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
# The main ThePersistent class without ACL checking. All system tables
# without ACL should grow from this class
# ------------------------------------------------------------------------

package ePortal::ThePersistent::Dual;
    our $VERSION = '4.5';
	use base qw/ePortal::ThePersistent::Support/;

	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang

################################################################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
	$self->SUPER::initialize(@_);
    if (! $self->attribute('id')) {
        $self->add_attribute( id => { type => 'ID', dtype => 'Number', default => 1 });
    }

	$self->_id(1);
}##initialize

############################################################################
sub restore	{	#11/22/01 11:49
############################################################################
	1;
}##restore


############################################################################
sub restore_where	{	#11/22/01 11:52
############################################################################
	my $self = shift;

	return $self->{dual_restored} = 1;
}##restore_where

############################################################################
sub restore_next	{	#11/22/01 11:50
############################################################################
	my $self = shift;
	my $result = $self->{dual_restored};
	$self->{dual_restored} = undef;
	return $result;
}##restore_next


############################################################################
sub delete	{	#11/22/01 11:53
############################################################################
	1;
}##delete


############################################################################
sub update	{	#11/22/01 11:53
############################################################################
	1;
}##update


############################################################################
sub insert	{	#11/22/01 11:53
############################################################################
	1;
}##insert


1;

__END__

