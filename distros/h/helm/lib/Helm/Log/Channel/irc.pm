package Helm::Log::Channel::irc;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use DateTime;
use AnyEvent;
use IO::Pipe;

BEGIN {
    eval { require AnyEvent::IRC::Client };
    die "Could not load AnyEvent::IRC::Client. It must be installed to use Helm's irc logging"
      if $@;
}

extends 'Helm::Log::Channel';
has irc_pipe    => (is => 'ro', writer => '_irc_pipe');
has pipes       => (is => 'ro', writer => '_pipes', isa => 'HashRef');
has is_parallel => (is => 'rw', isa    => 'Bool', default => 0);
has irc_pause   => (is => 'ro', writer => '_irc_pause', isa => 'Int', default => 0);
has prefix      => (is => 'rw', isa => 'Str', default => '');

my $DISCONNECT = 'Disconnecting';

# first parse the IRC URI into some parts that we can use to create an IRC connection.
# Then fork off an IRC worker process to go into an event loop that will read input
# from the main process via a pipe and then output that to the IRC server. We need
# to do it in an event loop because it needs to also respond asynchronously to the
# IRC server for pings and such.
sub initialize {
    my ($self, $helm) = @_;
    my $options = $helm->extra_options;
    my $pause = $options->{'irc-pause'} || $options->{'irc_pause'};
    $self->_irc_pause($pause) if $pause;

    my %irc_info;

    # file the file and open it for appending
    my $uri = $self->uri;
    if ($uri->authority =~ /@/) {
        my ($nick, $host) = split(/@/, $uri->authority);
        $irc_info{nick}   = $nick;
        $irc_info{server} = $host;
    } else {
        $irc_info{nick}   = 'helm';
        $irc_info{server} = $uri->authority;
    }
    $helm->die("No IRC server given in URI $uri") unless $irc_info{server};

    # get the channel
    my $channel = $uri->path;
    $helm->die("No IRC channel given in URI $uri") unless $channel;
    $channel =~ s/^\///;    # remove leading slash
    $channel = "#$channel" unless $channel =~ /^#/;
    $irc_info{channel} = $channel;

    # do we need a password
    my $query = $uri->query;
    if ($query && $query =~ /(?:^|&|;)(pass|pw|password|passw|passwd)=(.*)(?:$|&|;)/) {
        $irc_info{password} = $1;
    }

    # do we have a port?
    if ($irc_info{server} =~ /:(\d+)$/) {
        $irc_info{port} = $1;
        $irc_info{server} =~ s/:(\d+)$//;
    } else {
        $irc_info{port} = 6667;
    }

    # setup a pipe for communicating
    my $irc_pipe = IO::Pipe->new();

    # fork off a child process
    my $pid = fork();
    $helm->die("Couldn't fork IRC bot process") if !defined $pid;
    if ($pid) {
        # parent here
        $irc_pipe->writer;
        $irc_pipe->autoflush(1);
        $self->_irc_pipe($irc_pipe);
        Helm->debug("Parent IRC pipe set up");
    } else {
        Helm->debug("Child IRC worker process");
        # child here
        $irc_pipe->reader;
        $irc_pipe->autoflush(1);
        Helm->debug("Child IRC pipe set up");
        $self->_irc_events($irc_pipe, %irc_info);
    }
}

sub finalize {
    my ($self, $helm) = @_;

    Helm->debug("IRC channel finalized: Nothing to do");
}

sub start_server {
    my ($self, $server) = @_;
    $self->SUPER::start_server($server);
    $self->_say("BEGIN Helm task \"" . $self->task . "\" on $server");
}

sub end_server {
    my ($self, $server) = @_;
    $self->SUPER::end_server($server);
    $self->_say("END Helm task \"" . $self->task . "\" on $server");
}

sub debug {
    my ($self, $msg) = @_;
    $self->_say("[debug] $msg");
}

sub info {
    my ($self, $msg) = @_;
    $self->_say("$msg");
}

sub warn {
    my ($self, $msg) = @_;
    $self->_say("[warn] $msg");
}

sub error {
    my ($self, $msg) = @_;
    $self->_say("[error] $msg");
}

sub _say {
    my ($self, $msg) = @_;
    my $prefix = $self->prefix;
    Helm->debug("Sending message to IO worker: $prefix$msg");
    $self->irc_pipe->print("MSG: $prefix$msg\n") or CORE::die("Could not print message to IO Worker: $!");
}

sub _irc_events {
    my ($self, $irc_pipe, %args) = @_;
    my $irc  = AnyEvent::IRC::Client->new();
    my $done = AnyEvent->condvar;
    my $io_watcher;

    $irc->reg_cb(
        join => sub {
            my ($irc, $nick, $channel, $is_myself) = @_;
            Helm->debug("IRC worker joined channel $channel");
            # send the initial message
            if ($is_myself && $channel eq $args{channel}) {
                $io_watcher = AnyEvent->io(
                    fh   => $irc_pipe,
                    poll => 'r',
                    cb   => sub {
                        my $msg = <$irc_pipe>;
                        if(!$msg) {
                            Helm->debug("IRC worker ran out of pipe");
                            $irc->send_msg(PRIVMSG => $channel, $DISCONNECT);
                            undef $io_watcher;
                        } else {
                            chomp($msg);
                            if ($msg =~ /^MSG: (.*)/) {
                                my $content = $1;
                                chomp($content);
                                if( my $secs = $self->irc_pause ) {
                                    Helm->debug("IRC worker sleeping for $secs seconds");
                                    sleep($secs);
                                }
                                Helm->debug("IRC worker sending message to IRC channel: $content");
                                $irc->send_msg(PRIVMSG => $channel, $content);
                            }
                        }
                    }
                );
            }
        }
    );

    # we aren't done until the server acknowledges the send disconnect message
    $irc->reg_cb(
        sent => sub {
            my ($irc, $junk, $type, $channel, $msg) = @_;
            if( $type eq 'PRIVMSG' && $msg eq $DISCONNECT ) {
                Helm->debug("IRC channel received DISCONNECT message");
                $done->send();
            }
        }
    );

    Helm->debug("IRC worker connecting to server $args{server}");
    $irc->connect($args{server}, $args{port}, {nick => $args{nick}});
    Helm->debug("IRC worker trying to join channel $args{channel}");
    $irc->send_srv(JOIN => ($args{channel}));
    Helm->debug("IRC worker waiting for work");
    $done->recv;
    Helm->debug("IRC worker done with work, disconnecting");
    $irc->disconnect();
    exit(0);
}

# we already have an IRC bot forked off which has a pipe to our main process for
# communication. But if we then share that pipe in all our children we'll end up
# with garbled messages. So we need to fork off another worker process which has
# multiple pipes, one for each possible server that we'll be executing tasks on.
# This extra IO worker process will multi-plex the output coming from those pipes
# into something reasonable for the IRC bot to handle.
sub parallelize {
    my ($self, $helm) = @_;
    $self->is_parallel(1);

    # if we're going to do parallel stuff, then create a pipe for each server now
    # that we can use to communicate with the child processes later
    my %pipes = map { $_->name => IO::Pipe->new } (@{$helm->servers});
    $self->_pipes(\%pipes);

    # fork off an IO worker process
    my $pid = fork();
    $helm->die("Couldn't fork IRC IO worker process") if !defined $pid;
    if (!$pid) {
        Helm->debug("IO worker forked");
        # child here
        my %pipe_cleaners;
        my $all_clean = AnyEvent->condvar;
        foreach my $server (keys %pipes) {
            my $pipe = $pipes{$server};
            $pipe->reader;

            # create an IO watcher for this pipe
            Helm->debug("IO worker setting up AnyEvent reads on pipe for $server");
            $pipe_cleaners{$server} = AnyEvent->io(
                fh   => $pipe,
                poll => 'r',
                cb   => sub {
                    my $msg = <$pipe>;
                    if ($msg) {
                        Helm->debug("Printing message to IRC PIPE: $msg");
                        $self->irc_pipe->print($msg) or CORE::die "Could not print message to IRC PIPE: $!";
                    } else {
                        delete $pipe_cleaners{$server};
                        Helm->debug("Removing IO pipe for $server");
                        # tell the main program we're done if this is the last broom
                        $all_clean->send unless %pipe_cleaners;
                    }
                },
            );
        }

        Helm->debug("Waiting for IO to send to IRC worker process");
        $all_clean->recv;
        Helm->debug("All done with IO to send to IRC worker process");
        exit(0);
    }
}

# we've been forked, and if it's a child we want to initialize the pipe
# for this worker child's server
sub forked {
    my ($self, $type) = @_;

    if ($type eq 'child') {
        Helm->debug("Forked worker process for " . $self->current_server->name);
        my $pipes = $self->pipes;
        my $pipe  = $pipes->{$self->current_server->name};
        $pipe->writer();
        $pipe->autoflush(1);
        $self->_irc_pipe($pipe);
        $self->prefix('[' . $self->current_server->name . '] ');
    }
}

__PACKAGE__->meta->make_immutable;

1;
