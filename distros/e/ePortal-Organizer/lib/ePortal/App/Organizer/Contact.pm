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


package ePortal::App::Organizer::Contact;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ParentACL/;

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
    $p{Attributes}{title} ||= {
            label => { rus => 'Ф.И.О.', eng => 'Name'},
            size => 50,
        };
    $p{Attributes}{company} ||= {
            label => { rus => 'Место работы', eng => 'Company'},
            size => 50,
        };
    $p{Attributes}{job} ||= {
            label => {rus => 'Должность', eng => 'Appointment'},
            size => 50,
        };
    $p{Attributes}{phone_w} ||= {
        label => {rus => 'Телефон раб.', eng => 'Phone w.'},
        };
    $p{Attributes}{phone_h} ||= {
        label => {rus => 'Телефон дом.', eng => 'Phone. h.'},
        };
    $p{Attributes}{addr_w} ||= {
        label => {rus => 'Адрес раб.', eng => 'Address w.'},
        };
    $p{Attributes}{addr_h} ||= {
        label => {rus => 'Адрес дом.', eng => 'Address h.'},
        };
    $p{Attributes}{email} ||= {
        label => {rus => 'Эл.почта.', eng => 'e-mail'},
        };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{memo} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Проверка данных перед сохранением объекта
# Parameters: not null - проверка перед insert
# Returns: Строку с описанием ошибки или undef;
#
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

	# Простые проверки на наличие данных.
	unless ( $self->title ) {
		return pick_lang(rus => "Не указаны Ф.И.О. человека", eng => 'No person name');
	}

	undef;
}##validate



############################################################################
sub restore_where	{	#12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

	$p{order_by} = 'title' if not defined $p{order_by};

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


1;

