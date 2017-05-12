#
# Copyright (c) 2003,2004,2005 Alexander Taler (dissent@0--0.org)
#
# All rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#

package VCS::LibCVS::Datum::TagSpec;

use strict;
use Carp;

=head1 NAME

VCS::LibCVS::Datum::TagSpec - A CVS datum for a tag specification

=head1 SYNOPSIS

  $string = VCS::LibCVS::Datum::TagSpec->new("Trelease_1_01");

=head1 DESCRIPTION

The concatentation of a tag type and value, like:

  Trelease_1_01
  D2002.11.18.05.00.00

These are the tag types for LibCVS:

  VCS::LibCVS::Datum::TagSpec::TYPE_BRANCH      (T)
  VCS::LibCVS::Datum::TagSpec::TYPE_DATE        (D)
  VCS::LibCVS::Datum::TagSpec::TYPE_NONBRANCH   (N)
  VCS::LibCVS::Datum::TagSpec::TYPE_REVISION    (R)

This usage deviates from that in CVS, which is:
(This should be validated for accuracy.)

  D  A date tag
  T  In an entry line is any named symbolic or revision tag
     In a directory (CVS/Tag) indicates a branch tag
  N  In a directory (CVS/Tag) indicates a non-branch tag

=head1 SUPERCLASS

VCS::LibCVS::Datum

=cut

###############################################################################
# Class constants
###############################################################################

use constant REVISION => '$Header: /cvsroot/libcvs-perl/libcvs-perl/VCS/LibCVS/Datum/TagSpec.pm,v 1.11 2005/10/10 12:52:12 dissent Exp $ ';

use vars ('@ISA');
@ISA = ("VCS::LibCVS::Datum");

# TYPE_* constants are documented in the class description above
use constant TYPE_BRANCH    => "T";
use constant TYPE_DATE      => "D";
use constant TYPE_NONBRANCH => "N";
use constant TYPE_REVISION  => "R";

###############################################################################
# Class variables
###############################################################################

###############################################################################
# Private variables
###############################################################################

# $self->{Type}      The type of tag, one of TYPE_* constants
# $self->{Name}      The tag as a scalar string
# $self->{TagSpec}   The tag spec as understood by CVS, unchanged

###############################################################################
# Class routines
###############################################################################

sub new {
  my $class = shift;

  my $that = $class->SUPER::new(@_);

  ($that->{Type}, $that->{Name}) = ($that->{TagSpec} =~ /(.)(.*)/);

  # A tag which starts with an alpha is a revision tag, so update Type
  if ($that->{Name} =~ /^[0-9]/) {
    $that->{Type} = TYPE_REVISION;
  }

  return $that;
}

###############################################################################
# Instance routines
###############################################################################

=head1 INSTANCE ROUTINES

=head2 B<get_name()>

$tag_string = $tagspec->get_name()

=over 4

=item return type: scalar string

=back

Returns the name of the tagspec as a string

=cut

sub get_name {
  my $self = shift;
  return $self->{Name};
}

=head2 B<get_type()>

$tag_type = $tagspec->get_type()

=over 4

=item return type: scalar string

one of VCS::LibCVS::Datum::TagSpec::TYPE_*

=back

Returns the type of the tagspec

=cut

sub get_type {
  my $self = shift;
  return $self->{Type};
}

###############################################################################
# Private routines
###############################################################################

sub _data_names { return ("TagSpec"); }

=head1 SEE ALSO

  VCS::LibCVS::Datum

=cut

1;
