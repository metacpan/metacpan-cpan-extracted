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

package ePortal::ThePersistent::DataType::VarChar;
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

sub value {
  my $self = shift;

  ### set the value ###
  if (@_) {
    my $value = shift;
    $value = undef if defined($value) and $value eq '';

    ### check the length ###
    if ($self->{maxlength} and $value and (length($value) > $self->{maxlength})) {
        $value = substr($value, 0, $self->{maxlength});
    }
    $self->{Value} = $value;
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

__END__
