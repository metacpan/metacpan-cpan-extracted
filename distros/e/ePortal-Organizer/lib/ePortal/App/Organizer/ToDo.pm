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


package ePortal::App::Organizer::ToDo;
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
    $p{Attributes}{title} ||= {};
    $p{Attributes}{status} ||= {
            label => {rus => 'Состояние', eng => 'Status'},
            maxlength => 16,
            #description => 'undone,done',
            fieldtype => 'popup_menu',
            values => [undef, 'notstarted', 'undone', 'done'],
            labels => {
                undef => '---',
                notstarted => pick_lang(rus => "не начато", eng => "not started"),
                undone => pick_lang(rus => "в работе", eng => "started"),
                done => pick_lang(rus => "закончено", eng => "finished"),
                },
            default => 'undone',
        };
    $p{Attributes}{datestart} ||= {
            label=> {rus => 'Дата начала', eng => 'Start date'},
            dtype => 'Date',
            default => 'now',
        };
    $p{Attributes}{dateend} ||= {
            label => {rus => 'Срок дела', eng => 'Estimated date'},
            dtype => 'Date',
        };
    $p{Attributes}{datecompleted} ||= {
            label => {rus => 'Дата окончания', eng => 'Date completed'},
            dtype => 'Date',
        };
    $p{Attributes}{priority} ||= {
            label => {rus => 'Приоритет', eng => 'Priority'},
            dtype => 'Number',
            maxlength => 2,
            default => 5,
            fieldtype => 'popup_menu',
            values => [ 1..9 ],
        };
    $p{Attributes}{memo} ||= {
            label => {rus => 'Суть дела', eng => 'Memo'},
            size => 60,
            maxlength => 4000,
            fieldtype => 'textarea',
        };
    $p{Attributes}{ts} ||= {};

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub restore_where	{	#12/24/01 4:00
############################################################################
    my ($self, %p) = @_;

	if (exists $p{undone}) {
		$self->add_where( \%p, "status<>'done'");
    }
    delete $p{undone};

    if ($p{status}) {
        $self->add_where( \%p, 'status=?', $p{status});
    }
    delete $p{status};

    $p{order_by} = 'status DESC, priority, title' if not $p{order_by};
	$self->SUPER::restore_where(%p);
}##restore_where


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
		return pick_lang(rus => "Не указано наименование дела", eng => 'No job name');
	}

	undef;
}##validate





############################################################################
sub htmlField	{	#12/27/01 10:50
############################################################################
	my $self = shift;
	my $attr = lc shift;
	my %p = @_;

	my $html = $self->SUPER::htmlField($attr, %p);

	if ($attr eq 'status') {
		$html .= "&nbsp;&nbsp;" . $self->htmlValue("datecompleted");
	}
	$html;
}##htmlField

############################################################################
# Function: value
# Description: Ala trigger. Adjust some attributes when any value changes
############################################################################
sub value	{	#10/04/01 4:34
############################################################################
	my $self = shift;
	my $attr = lc shift;

	if (@_) {	# Assing new value
		my $newvalue = shift;
		if ($attr eq 'status') {
			if ($newvalue eq 'done') {
				$self->datecompleted('now');
			}
		}
		return $self->SUPER::value($attr, $newvalue);

	} else {
		return $self->SUPER::value($attr);
	}
}##value


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::App::Organizer::Organizer;
    $C->restore($self->org_id);
    return $C;
}##parent



1;

