package Helm::Log::Channel::email;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use DateTime;

BEGIN {
    eval { require Email::Simple };
    die "Could not load Email::Simple. It must be installed to use Helm's email logging" if $@;
    eval { require Email::Simple::Creator };
    die "Could not load Email::Simple::Creator. It must be installed to use Helm's email logging" if $@;
    eval { require Email::Sender::Simple };
    die "Could not load Email::Sender::Simple. It must be installed to use Helm's email logging" if $@;
    eval { require Email::Valid };
    die "Could not load Email::Valid::Simple. It must be installed to use Helm's email logging" if $@;
}

extends 'Helm::Log::Channel';
has email_address => (is => 'ro', writer => '_email_address', isa => 'Str');
has email_body    => (is => 'ro', writer => '_email_body',    isa => 'Str', default => '');
has from          => (is => 'ro', writer => '_from',          isa => 'Str', default => '');
has is_parallel   => (is => 'ro', writer => '_is_parallel',   isa => 'Bool', default => 0);
has is_parent     => (is => 'ro', writer => '_is_parent',     isa => 'Bool', default => 0);
has pipes => (is => 'ro', writer => '_pipes', isa => 'HashRef', default => sub { {} });

# fork off an IO worker which has a pipe for each server we're going to do work
# on. Use that pipe to communicate with the process doing the parallel work
# on that server. So when another child process does $helm->log->info... that
# output will end up going from that child process over a pipe reserved for that
# process's server, to this IO worker process which will then append it to the email body.
sub parallelize { 
    my ($self, $helm) = @_;
    $self->_is_parallel(1);

    # if we're going to do parallel stuff, then create a pipe for each server now
    # that we can use to communicate with the child processes later
    Helm->debug("Creating a pipe for each server target for multiplexing output");
    my %pipes = map { $_->name => IO::Pipe->new } (@{$helm->servers});

    # and one for the parent so it's handled like everything else
    Helm->debug("Parent process should also communicate over multiplexing pipes");
    my $parent_pipe = IO::Pipe->new();
    $pipes{parent} = $parent_pipe;

    $self->_pipes(\%pipes);

    # fork off an IO worker process
    my $pid = fork();
    $helm->die("Couldn't fork email IO worker process") if !defined $pid;
    if ($pid) {
        # parent here
        $self->_is_parent(1);
        Helm->debug("Parent process pipe is a writer");
        $parent_pipe->writer;
        $parent_pipe->autoflush(1);
    } else {
        # child here
        my %pipe_cleaners;
        my $all_clean = AnyEvent->condvar;
        Helm->debug("Child process pipes are readers");
        foreach my $server (keys %pipes) {
            my $pipe = $pipes{$server};
            $pipe->reader;

            # create an IO watcher for this pipe
            Helm->debug("Setting up reading event for IO worker pipe for $server");
            $pipe_cleaners{$server} = AnyEvent->io(
                fh   => $pipe,
                poll => 'r',
                cb   => sub {
                    my $msg = <$pipe>;
                    if ($msg) {
                        Helm->debug("IO Worker Appending text to email body: $msg");
                        $self->_email_body($self->email_body . $msg);
                    } else {
                        Helm->debug("Pipe for $server has been disconnected");
                        delete $pipe_cleaners{$server};
                        # tell the main program we're done if this is the last pipe
                        $all_clean->send unless %pipe_cleaners;
                    }
                },
            );
        }

        Helm->debug("Waiting on child pipes to receive data");
        $all_clean->recv;
        Helm->debug("All child pipes have been read");
        Helm->debug("IO Worker sending email");
        $self->_send_email;
        exit(0);
    }
}

sub forked {
    my ($self, $type) = @_;

    if ($type eq 'child') {
        my $pipes       = $self->pipes;
        my $server_name = $self->current_server->name;
        my $pipe        = $pipes->{$server_name};
        Helm->debug("Console output now goes over writer pipe for $server_name");
        $pipe->writer();
        $pipe->autoflush(1);
    }
}


sub initialize {
    my ($self, $helm) = @_;

    # file the file and open it for appending
    my $uri = $self->uri;
    my $email = $uri->to;
    my %headers = $uri->headers();
    my $from = $headers{from} || $headers{From} || $headers{FROM};
    $helm->die(qq(No "From" specified in mailto URI $uri)) unless $from;

    # remove possible leading double slash if someone does "mailto://" instead of "mailto:"
    $email =~ s/^\/\///; 

    $helm->die(qq("$email" is not a valid email address)) unless Email::Valid->address($email);
    $self->_email_address($email);
    $self->_from($from);
}

sub finalize {
    my ($self, $helm) = @_;

    # the IO worker process will take care of sending the email
    # when we're in parallel mode
    $self->_send_email() unless $self->is_parallel;
}

sub start_server {
    my ($self, $server) = @_;
    $self->SUPER::start_server($server);

    if( $self->is_parallel ) {
        $self->_append_body("Starting task on $server");
    } else {
        my $line = '=' x 70;
        $self->_append_body("$line\n$server\n$line\n");
    }
}

sub end_server {
    my ($self, $server) = @_;
    $self->SUPER::end_server($server);

    if(!$self->is_parallel) {
        $self->_append_body("\n\n");
    }
}

sub debug {
    my ($self, $msg) = @_;
    $self->_append_body("[debug] $msg\n");
}

sub info {
    my ($self, $msg) = @_;
    $self->_append_body("$msg\n");
}

sub warn {
    my ($self, $msg) = @_;
    $self->_append_body("[warn] $msg\n");
}

sub error {
    my ($self, $msg) = @_;
    $self->_append_body("[error] $msg\n");
}

sub _prefix {
    my $self = shift;
}

sub _append_body {
    my ($self, $text) = @_;
    chomp($text);
    
    my $prefix;
    if( $self->is_parallel ) {
        my $ts = DateTime->now->strftime('%a %b %d %H:%M:%S %Y');
        my $server = $self->current_server->name;
        $prefix = "[$ts] [$server] ";
    } else {
        # indent content under the server label
        $prefix = $self->current_server ? '  ' : '';
    }

    if ($self->is_parallel) {
        my $pipe;
        if( $self->is_parent ) {
            Helm->debug("Sending text to IO worker over parent pipe: $text");
            $pipe = $self->pipes->{parent};
        } else {
            my $server = $self->current_server->name;
            Helm->debug("Sending text to IO worker over $server pipe: $text");
            $pipe = $self->pipes->{$server};
        }
        $pipe->print("$prefix$text\n");
    } else {
        Helm->debug("Appending text to email body: $text");
        $self->_email_body($self->email_body . $prefix . $text . "\n");
    }
}

sub _send_email {
    my $self = shift;
    # send the email
    Helm->debug("Sending email from " . $self->from . " to " . $self->email_address);
    my $email = Email::Simple->create(
        header => [
            To      => $self->email_address,
            From    => $self->from,
            Subject => 'HELM: Task ' . $self->task,
        ],
        body => $self->email_body,
    );
    Email::Sender::Simple->send($email);
    Helm->debug("Email sent");
}

__PACKAGE__->meta->make_immutable;

1;
