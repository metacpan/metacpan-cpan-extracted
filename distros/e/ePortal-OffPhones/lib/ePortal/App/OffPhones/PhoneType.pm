#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
#
#----------------------------------------------------------------------------


package ePortal::App::OffPhones::PhoneType;
	use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = '4.2';

	use ePortal::Global;
	use ePortal::Utils;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'OffPhones';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{format} ||= {
            label => {rus => 'Формат', eng => 'Format'},
        };
    $p{Attributes}{title} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	unless ( $self->title ) {
		return pick_lang(rus => "Не указано наименование", eng => 'No name');
	}
	unless ( $self->Format ) {
		return pick_lang(rus => "Не указан формат ввода", eng => 'No format definition');
	}

	undef;
}##validate



############################################################################
sub restore_where	{	#12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

	$p{order_by} = 'title' if not defined $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where



############################################################################
# Function: phones_count
# Description:
# Parameters:
# Returns:
#
############################################################################
sub phones_count	{	#04/18/02 4:37
############################################################################
	my $self = shift;

    $self->dbh->selectrow_array("SELECT count(*) from Phone where type_id=?", undef, $self->id);
}##phones_count

1;

