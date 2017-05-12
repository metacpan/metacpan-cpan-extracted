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

package ePortal::ThePersistent::DataType::Array;
    our $VERSION = '4.5';
    use Carp;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %p = @_;

    my $self = {
      Value => [],
      %p,
      };
    bless $self, $class;
    $self->value($self->{default}) if $self->{default};

    return $self;
}

sub value {
  my $self = shift;

  ### set the value ###
  if (@_) {
    my $value = shift;
    $value = [] if ref($value) ne 'ARRAY';
    $self->{Value} = [ @{$value} ]; # duplicate array
  }

  ### return the value ###
  $self->{Value};
}



############################################################################
sub sql_value   {   #09/30/02 2:34
############################################################################
    my $self = shift;
    return $self->value();
}##sql_value

############################################################################
sub clear   {   #06/19/2003 11:38
############################################################################
    my $self = shift;
    $self->value( $self->{default} );
}##clear


1;
