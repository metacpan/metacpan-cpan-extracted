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

package ePortal::ThePersistent::Session;
    our $VERSION = '4.5';
	use base qw/ePortal::ThePersistent::Support/;

	use Carp qw/croak/;
	use ePortal::Global;
	use ePortal::Utils;		# import logline, pick_lang

################################################################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
	my $self = shift;
	$self->SUPER::initialize(@_);
    $self->add_attribute (
        id => { type => 'ID',
                dtype => 'VarChar',
                maxlength => 255 },
                );
}##initialize

############################################################################
sub restore	{	#11/22/01 11:49
############################################################################
	my $self = shift;
	my $id = shift;

	$self->{wanted_id} = $id;
	if (exists $session{"st_s_$id"} and ref($session{"st_s_$id"}) eq 'HASH') {
		$self->data( $session{"st_s_$id"} );
		return 1;
	} else {
		return undef;
	}
}##restore


############################################################################
sub restore_where	{	#11/22/01 11:52
############################################################################
	my $self = shift;

    croak "restore_where is not supported by ".__PACKAGE__;
}##restore_where

############################################################################
sub restore_next	{	#11/22/01 11:50
############################################################################
	my $self = shift;
	$self->clear;
	undef;
}##restore_next


############################################################################
sub delete	{	#11/22/01 11:53
############################################################################
	1;
}##delete


############################################################################
sub update	{	#11/22/01 11:53
############################################################################
	my $self = shift;
    return undef if ! $self->check_id();

	my $id = ($self->_id)[0];
	$session{"st_s_$id"} = $self->data();
	1;
}##update


############################################################################
sub insert	{	#11/22/01 11:53
############################################################################
	my $self = shift;
    $self->_id($self->{wanted_id} || 1);
	$self->update;
}##insert


1;

__END__

