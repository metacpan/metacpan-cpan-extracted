#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::FileName;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::FileName - A CVS datum for the name of a file

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::FileName->new("/home/cvs/dir");

=head1 DESCRIPTION

The name of a file.

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/FileName.pm,v 1.8 2005/10/10 12:52:12 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

###############################################################################
# Class routines
###############################################################################

###############################################################################
# Instance routines
###############################################################################

###############################################################################
# Private routines
###############################################################################

sub _data_names { return ("FileName"); }

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
