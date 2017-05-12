package Test::Synopsis::__TestBait_Test11DATAInPod;

# Dummy module used during testing of Test::Synopsis. Needs to be in the lib/
# dir of the Test-Synopsis distribution to Test::Synopsis can find it.
#
# This module has a __DATA__ in the synopsis code along with an error
# that Test::Synopsis should be detecting

use strict;
use warnings;

# VERSION

1;

=pod

=head1 SYNOPSIS

Testing stuff:

    print "Foos!\n";

    $x; # uninitialized!

    __DATA__

=head1 DESCRIPTION

bleh

=cut
