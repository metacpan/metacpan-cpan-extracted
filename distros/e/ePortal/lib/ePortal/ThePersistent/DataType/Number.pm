#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

package ePortal::ThePersistent::DataType::Number;
    use strict;
    use Carp;

    our $VERSION = '4.5';

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %p = @_;

  my $self = { Value => undef, %p };

  bless $self, $class;
  $self->value($self->{default}) if $self->{default};

  return $self;
}

########################################################################
# value
########################################################################

sub value {
  my $self = shift;

  ### set the value ###
  if (@_) {
    my $value = shift;
    $value = undef if defined($value) and $value eq '';

    if ($self->{maxlength} and $value and (length($value) > $self->{maxlength})) {
        carp "Length of value [$value] is greater then maxlength";
    }

    $self->{Value} = $value;

  }
  return unless defined wantarray;

    ### return the value ###
    if ($self->{scale} == 0) {
        return $self->{Value};
    } else {
        return sprintf '%.'.$self->{scale}.'f', $self->{Value};
    }
}

############################################################################
# Function: sql_value
# Description:
# Parameters:
# Returns:
#
############################################################################
sub sql_value   {   #09/30/02 2:34
############################################################################
    my $self = shift;
    return $self->value();
}##sql_value


########################################################################
# Function:    _parse_number
# Description: Parses the number into digits before and after the
#              decimal point.  Insignificant trailing zeroes will be
#              truncated.
# Parameters:  None
# Returns:     None
########################################################################
sub _parse_number {
  my $value = shift;

  my $before = '';
  my $after = '';

  if (defined $value) {
    if ($value =~ /^[+-]?(\d*)\.?(\d*)$/o) {
      $before = $1;  $after = $2;
      $after =~ s/0+$//;  ### remove trailing zeroes ###
    } else {
      croak "'$value' is not a number";
    }
  }

  ($before, $after);
}

############################################################################
sub clear   {   #06/19/2003 11:38
############################################################################
    my $self = shift;
    $self->value( $self->{default} );
}##clear


1;
