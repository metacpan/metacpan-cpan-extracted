package Helm::Task::unlock;
use strict;
use warnings;
use Moose;

extends 'Helm::Task';

# nothing to do here
sub validate { } 

sub help {
    my ($self, $task) = @_;
    my $text = <<END;
Clears out a Helm lock on a remote server. This is helpful if something
goes awry and a lock is stuck preventing you from running helm against
that remote server. Note: it probably doesn't make any sense to run this
task with the "--lock both" or "--lock remote" options.

CAUTION: Make sure that the lock is really an artefact of a previous
run and not something currently being run by someone else or bad things
could happen.

    helm unlock
END
}


sub execute {
    my ($self, %args) = @_;
    my $server  = $args{server};
    my $ssh     = $args{ssh};
    my $helm    = $self->helm;

    $helm->log->info("Clearing remote lock on $server");
    # kind of icky to be using the private message like this
    $helm->_release_remote_lock($ssh);
}

__PACKAGE__->meta->make_immutable;

1;
