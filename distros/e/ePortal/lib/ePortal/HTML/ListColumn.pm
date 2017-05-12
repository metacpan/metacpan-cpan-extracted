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

package ePortal::HTML::ListColumn;
    our $VERSION = '4.5';

	use Carp;
	use ePortal::Utils;

############################################################################
# Function: new
# Description: object constructor
# Parameters:
# 	see initialize
# Returns:
# 	the object
#
############################################################################
sub new	{	#09/07/01 2:04
############################################################################
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %p = @_;
	my $self = {};

	bless $self, $class;
	$self->initialize(%p);

	# check required parameters
	if (!defined $self->{id}) {
		carp "Column ID is not defined";
	}
	if (!defined $self->{obj}) {
		carp "nothing to draw. Object ?";
	}
	return $self;
}##new


############################################################################
# Function: initialize
# Description: Initialize the column
# Parameters: many
############################################################################
sub initialize	{	#09/07/01 2:07
############################################################################
	my $self = shift;
	my %p = @_;

	# Set some defaults.
	$self->{align} 	||= undef;
	$self->{class}	||= undef;
	$self->{content}||= undef;
	$self->{id}		||= undef;	# Column ID (name)
	$self->{nowrap}	||= undef;
	$self->{obj}	||= undef;	# the object to draw
    $self->{objtype}||= undef;  # Somethimes its differs from ref($obj)
	$self->{title} 	||= '';		# table header
	$self->{url}	||= undef;	# Link url on entire content
	$self->{valign}	||= undef;
	$self->{width}	||= undef;
	$self->{method} ||= undef;	# method name to call
	$self->{src}	||= undef;	# image source

	$self->{acl} 	||= undef;
	$self->{delete} ||= undef;
	$self->{edit} 	||= undef;
	$self->{checkbox} ||= undef;
    $self->{export}   ||= undef;
    $self->{sorting}  ||= undef; # Sort by clause for the column

	# overwrite known initialization parameters
	foreach my $key (keys %$self) {
		$self->{$key} = $p{$key} if exists $p{$key};
	}

	if ($self->{title} eq '' and ref($self->{obj})) {
		my $a = $self->{obj}->attribute($self->{id});
		$self->{title} = pick_lang($a->{label}) if $a;
    }

	$self;
}##initialize

############################################################################
# Function: content
# Description: This is cell content
############################################################################
sub content	{	#09/10/01 12:57
############################################################################
	my $self = shift;
	my $id = $self->{id};
	my $content;

	if (ref $self->{content} eq 'CODE') {
		$content = &{$self->{content}}($self->{obj});
    } elsif ($self->{obj}->attribute($id) ) {
#		$content = $self->{obj}->value($id);
		$content = $self->{obj}->htmlValue($id);
	} else {
		$content = "cell content of $id";
	}

	return $content;
}##content

############################################################################
# Function: td_params
# Description: calculates hash with parameters to CGI::td
# Returns:
# 	hash ref
#
############################################################################
sub td_params	{	#09/10/01 2:11
############################################################################
	my $self = shift;
	my $p = {};

	$p->{nowrap} = 1 if $self->{nowrap};
	foreach (qw/width class align valign/) {
		$p->{"-$_"} = $self->{$_} if $self->{$_};
	}

    return $p;
}##td_params


############################################################################
# Function: prepare_system_column
# Description: Do some work on each row for system column
############################################################################
sub prepare_system_column	{	#09/13/01 8:47
############################################################################
	my $self = shift;

	# show or not?
	foreach my $i (qw/checkbox edit acl export delete/) {
		if (ref $self->{$i} eq 'CODE') {
			$self->{"show_$i"} = &{$self->{$i}}( $self->{obj} );
		} elsif (defined $self->{$i}) {
			$self->{"show_$i"} = eval $self->{$i};
		}
    }
}##prepare_system_column

1;
