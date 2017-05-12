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


package ePortal::App::OffPhones::Department;
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
    $p{Attributes}{parent_id} ||= {
            label => {rus => 'Вышестоящее подразделение', eng => 'Department'},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => \&ePortal::App::OffPhones::Department::load_popup_menu,
            default => 0,
        };
    $p{Attributes}{title} ||= {};
    $p{Attributes}{dept_code} ||= {
            label => {rus => 'Код подразделения', eng => 'Name'},
            size  => 10,
        };
    $p{Attributes}{ts} ||= {};

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

	unless ( defined $self->parent_id ) {
		return pick_lang(rus => "Не указано вышестоящее подразделение ", eng => 'No parent');
	}

	undef;
}##validate



############################################################################
sub restore_where	{	#12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

	$p{order_by} = 'parent_id,title' if not defined $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub load_popup_menu	{	#04/08/02 1:39
############################################################################
	my $self = shift;
	my (@values, %labels);

	push @values, 0;
	$labels{0} = "Телефоны";

	my $parent = $self->parent;
	if ($parent) {
		push @values, $parent->id;
		$labels{$self->parent_id} = $parent->title;
	}

    return (\@values, \%labels);
}##load_popup_menu



############################################################################
sub parent	{	#04/09/02 9:23
############################################################################
	my $self = shift;
	my $dpt = new ePortal::App::OffPhones::Department;

	if ($dpt->restore($self->parent_id)) {
		return $dpt;
	} else {
		return undef;
	}
}##parent


############################################################################
sub children	{	#04/09/02 11:09
############################################################################
	my $self = shift;
	my $dpt = new ePortal::App::OffPhones::Department;
	$dpt->restore_where(parent_id => $self->id);
	return $dpt;
}##children


############################################################################
sub delete	{	#04/09/02 11:10
############################################################################
	my $self = shift;
	my $client = new ePortal::App::OffPhones::Client;

	$client->restore_where( dept_id => $self->id);
	while($client->restore_next) {
		warn "delete Client";
		$result += $client->delete;
	}
	warn "Clients deleted";
	$result += $self->SUPER::delete();
	return $result;
}##delete

1;

