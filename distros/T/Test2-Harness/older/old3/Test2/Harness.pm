package Test2::Harness;
use strict;
use warnings;

use File::Temp qw/tempdir/;

use Test2::Harness::HashBase qw/-listen/;

sub init {
    my $self = shift;
    $self->{+LISTEN} ||= tempdir("T2HARNESS-$$-XXXXXXXX", CLEANUP => 0);
}

1;

__END__

Harness - directory

Runner -spawns- Worker

@events = Runner->poll

@ordered = aggregator->add(@events)

Renderer->render(@ordered)



