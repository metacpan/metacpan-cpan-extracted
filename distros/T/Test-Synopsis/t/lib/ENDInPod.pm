package Test::Synopsis::__TestBait_ENDinPod;

# Dummy module used during testing of Test::Synopsis. Needs to be in the lib/
# dir of the Test-Synopsis distribution to Test::Synopsis can find it.
#
# This module has an __END__ in the synopsis code; it shouldn't
# break Test::Synopsis

use strict;
use warnings;

# VERSION

1;

=pod

=head1 SYNOPSIS

Testing stuff:

    print "Foos!\n";

    __END__

    BLARGHS!

=head1 DESCRIPTION

bleh

=cut
