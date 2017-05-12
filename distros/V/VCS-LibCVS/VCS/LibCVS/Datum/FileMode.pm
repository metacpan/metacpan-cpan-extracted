#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::FileMode;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::FileMode - A CVS datum for the mode of a file

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::FileMode->new("u=rw,g=rw,o=r");

=head1 DESCRIPTION

The mode of a file, simple UNIX-style file permissions, like "u=rw,g=rw,o=r".

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/FileMode.pm,v 1.10 2005/10/10 12:52:12 dissent Exp $ ';

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

sub new {
  my $class = shift;
  my $that = $class->SUPER::new(@_);

  if ($that->{Mode} !~ /^([ugo]+=[rwx]*)(,[ugo]+=[rwx]*)+$/) {
    if (-e $that->{Mode}) {
      $that->_from_filename();
    } else {
      confess "Bad mode: $that->{Mode}"
    }
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

###############################################################################
# Private routines
###############################################################################

sub _data_names { return ("Mode"); }

# Get the mode of the file from its name
sub _from_filename {
  my $self = shift;
  my $num = (stat($self->{Mode}))[2] & 0777;
  my $sym = "u=" . _n2s_digit($num >> 6) . ",";
  $sym   .= "g=" . _n2s_digit($num >> 3) . ",";
  $sym   .= "o=" . _n2s_digit($num);
  $self->{Mode} = $sym;
}

# Convert a single digit from numerical to symbolic
sub _n2s_digit {
  my $n = shift;
  return (($n & 04)?"r":"") . (($n & 02)?"w":"") . (($n & 01)?"x":"");
}

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
