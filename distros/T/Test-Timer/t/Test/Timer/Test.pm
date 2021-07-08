## no critic (RequireVersionVar ProhibitUnusedPrivateSubroutines)

package Test::Timer::Test;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(_sleep);

sub _sleep {
    my $interval = shift;

    sleep $interval;

    return $interval;
}

1;
