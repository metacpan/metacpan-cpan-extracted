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


package ePortal::App::OffPhones::Phone;
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
    $p{Attributes}{type_id} ||= {
            label => {rus => 'Тип номера', eng => 'Phone type'},
            dtype => 'Number',
            maxlength => 9,
        };
    $p{Attributes}{client_id} ||= {
            label => {rus => 'Клиент', eng => 'Client'},
            dtype => 'Number',
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
sub parent	{	#04/09/02 1:31
############################################################################
	my $self = shift;
	my $client = new ePortal::App::OffPhones::Client;
	if ($client->restore($self->client_id)) {
		return $client;
	} else {
		return undef;
	}
}##parent




1;

