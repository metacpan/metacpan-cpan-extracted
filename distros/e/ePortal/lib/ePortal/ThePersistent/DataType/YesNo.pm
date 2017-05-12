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

package ePortal::ThePersistent::DataType::YesNo;
    our $VERSION = '4.5';

	use strict;
    use Carp;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %p = @_;

  my $self = {%p};  ### allocate a hash for the object's data ###
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
    if (defined($value) and $value eq 'yes') {
			$self->{Value} = 1;
    } elsif (defined($value) and $value eq 'no') {
			$self->{Value} = 0;
    } elsif (defined($value) and $value) {
			$self->{Value} = 1;
		} else {
			$self->{Value} = 0;
		}
	}

	return $self->{Value};
}


############################################################################
sub sql_value   {   #09/30/02 3:51
############################################################################
    my $self = shift;
    $self->value();
}##sql_value

############################################################################
sub clear   {   #06/19/2003 11:38
############################################################################
    my $self = shift;
    $self->value( $self->{default} );
}##clear

1;
