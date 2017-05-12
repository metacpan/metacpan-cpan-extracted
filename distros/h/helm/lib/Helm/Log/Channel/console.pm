package Helm::Log::Channel::console;
use strict;
use warnings;
use Moose;
use Term::ANSIColor qw(colored color);
use IO::Pipe;
use AnyEvent;
use namespace::autoclean;

extends 'Helm::Log::Channel';
has pipes       => (is => 'ro', writer => '_pipes', isa     => 'HashRef');
has fh          => (is => 'ro', writer => '_fh');
has is_parallel => (is => 'rw', isa    => 'Bool',   default => 0);

my $LINE = '-' x 70;

sub initialize {
    my ($self, $helm) = @_;

    # default FH is STDERR
    Helm->debug("Initializing output handle to STDERR");
    my $fh = IO::Handle->new_from_fd(fileno(STDERR), 'w');
    $self->_fh($fh);
}

sub finalize {
    my ($self, $helm) = @_;
    # make sure the terminal is reset
    print color 'reset';
}

sub start_server {
    my ($self, $server) = @_;
    $self->SUPER::start_server($server);

    if ($self->is_parallel) {
        $self->output("Starting task on $server", 'blue');
    } else {
        $self->output("$LINE\n$server\n$LINE", 'blue');
    }
}

sub end_server {
    my ($self, $server) = @_;
    $self->SUPER::end_server($server);
    if (!$self->is_parallel) {
        $self->fh->print("\n");
    }
}

sub debug {
    my ($self, $msg) = @_;
    $self->output("[DEBUG] $msg", 'bright_blue');
}

sub info {
    my ($self, $msg) = @_;
    $self->output($msg, 'bright_green');
}

sub warn {
    my ($self, $msg) = @_;
    $self->output("[WARN] $msg", 'yellow');
}

sub error {
    my ($self, $msg) = @_;
    $self->output("[ERROR] $msg", 'red');
}

sub output {
    my ($self, $msg, @colors) = @_;
    my $prefix = $self->is_parallel ? '[' . $self->current_server->name . '] ' : '';
    $msg = "$prefix$msg\n";
    $msg = colored($msg, @colors) if @colors;
    $self->fh->print($msg);
}

# fork off an IO worker which has a pipe for each server we're going to do work
# on. Use that pipe to communicate with the process doing the parallel work
# on that server. So when another child process does $helm->log->info... that
# output will end up going from that child process over a pipe reserved for that
# process's server, to this IO worker process which will then send it to the console.
sub parallelize {
    my ($self, $helm) = @_;
    $self->is_parallel(1);

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
    $helm->die("Couldn't fork console IO worker process") if !defined $pid;
    if ($pid) {
        # parent here
        Helm->debug("Parent process pipe is a writer");
        $parent_pipe->writer;
        $parent_pipe->autoflush(1);
        $self->_fh($parent_pipe);
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
                        print STDERR $msg;
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
        exit(0);
    }
}

# we've been forked, and if it's a child we want to initialize the pipe
# for this worker child's server
sub forked {
    my ($self, $type) = @_;

    if ($type eq 'child') {
        my $pipes       = $self->pipes;
        my $server_name = $self->current_server->name;
        my $pipe        = $pipes->{$server_name};
        Helm->debug("Console output now goes over writer pipe for $server_name");
        $pipe->writer();
        $pipe->autoflush(1);
        $self->_fh($pipe);
    }
}

__PACKAGE__->meta->make_immutable;

1;
