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


package ePortal::App::Organizer::Notepad;
    use base qw/ePortal::ThePersistent::ParentACL/;
    our $VERSION = '4.2';

	use ePortal::Global;
	use ePortal::Utils;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'Organizer';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{org_id} ||= {
            label => {rus => "Органайзер", eng => "Organizer"},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => sub {
                my $self = shift;
                my $m = $ePortal->Application('Organizer')->stOrganizers(writable=>1);
                my ($values, $labels) = $m->restore_all_hash();
                push @{$values}, undef;
                $labels->{undef} = '---';
                return ($values, $labels);
            }
        };
    $p{Attributes}{category_id} ||= {
            label => {rus => "Категория", eng => "Category"},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => sub {
                my $self = shift;
                my $m = new ePortal::App::Organizer::Category;
                my ($values, $labels) = $m->restore_all_hash(undef,undef,'org_id='.$self->org_id);
                unshift @{$values}, undef;
                $labels->{undef} = '---';
                return ($values, $labels);
            }
        };
    $p{Attributes}{memo} ||= {
            label => {rus => 'Содержание заметки', eng => 'Memo'},
            size => 60,
            maxlength => 65000,
            fieldtype => 'textarea',
            columns => 60,  # for fieldtype
        };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{title} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	# Простые проверки на наличие данных.
	unless ( $self->title ) {
		return pick_lang(rus => "Не указано наименование заметки", eng => 'No memo name');
	}

	undef;
}##validate



############################################################################
sub restore_where	{	#12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

    $p{order_by} = 'title' if not $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::App::Organizer::Organizer;
    $C->restore($self->org_id);
    return $C;
}##parent




############################################################################
sub htmlSave	{	#06/29/01 12:06
############################################################################
	my $self = shift;
	my %params = @_;

	# request to create new folder
	if ($params{newfolder} ne '') {
		my $folder = new ePortal::NotepadFolder;
		$folder->title($params{newfolder});
		$folder->insert;
		$self->folder_id( $folder->id );
		delete $params{folder_id};
	}

	return $self->SUPER::htmlSave(%params);
}##htmlSave


1;

