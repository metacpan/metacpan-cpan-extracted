package Test::Synopsis::__TestBait_PlainTextInPod;

# Dummy module used during testing of Test::Synopsis. Needs to be in the lib/
# dir of the Test-Synopsis distribution to Test::Synopsis can find it.
#
# This module has plain text in the middle of the SYNOPSIS code; we should
# ignore it

use strict;
use warnings;

# VERSION

1;

=pod

=head1 SYNOPSIS

Print some foos:

    print "Foos!\n";

Blarg away:

    BLARGHS();

MOAR BLARGHS!

=head1 DESCRIPTION

bleh

=cut
