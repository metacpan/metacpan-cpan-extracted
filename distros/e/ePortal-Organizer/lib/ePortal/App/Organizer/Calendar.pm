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


package ePortal::App::Organizer::Calendar;
    use base qw/ePortal::ThePersistent::ParentACL/;
    our $VERSION = '4.2';

	use ePortal::Global;
	use ePortal::PopupEvent;
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
    $p{Attributes}{title} ||= {
        label => {rus => 'Содержание', eng => 'Name'},
        };
    $p{Attributes}{datestart} ||= {
            label=> {rus => 'Дата/время', eng => 'Start time'},
            dtype => 'DateTime',
            default => 'now',
        };
    $p{Attributes}{duration} ||= {
            label => {rus => 'Продолжительность (ЧЧ:ММ)', eng => 'Duration'},
            default => 30,
            dtype => 'Number',
            #description => "Duration in minutes",
        };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{memo} ||= {
        label => {rus => 'Суть дела', eng => 'Memo'},
    };

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
		return pick_lang(rus => "Не указано наименование дела", eng => 'No name');
	}

	unless ($self->datestart ) {
		return pick_lang(rus => "Не указана дата/время начала дела", eng => 'No start time');
	}

	undef;
}##validate



############################################################################
sub insert	{	#01/21/02 3:32
############################################################################
	my $self = shift;
	my $ret = $self->SUPER::insert(@_);

	if ($ret) {
		my $pe = new ePortal::PopupEvent::CalendarEvent($self);
		$pe->insert;
    }

	return $ret;
}##insert


############################################################################
sub update	{	#01/21/02 4:05
############################################################################
	my $self = shift;
	my $ret = $self->SUPER::update(@_);

	if ($ret) {
		my $pe = new ePortal::PopupEvent::CalendarEvent($self);
		$pe->save;
    }

	return $ret;
}##update


############################################################################
sub delete	{	#01/21/02 4:12
############################################################################
	my $self = shift;
	my $ret = $self->SUPER::delete(@_);

	if ($ret) {
		my $pe = new ePortal::PopupEvent::CalendarEvent;
		if ($pe->restore_where(originator => $self)) {
			$pe->delete if $pe->restore_next;
		}
	}

	return $ret;
}##delete

############################################################################
sub restore_where	{	#12/24/01 4:30
############################################################################
	my ($self, %p) = @_;

	if (exists $p{active_today}) {
		$self->add_where( \%p, 'datestart>=now() AND datestart<date_add(curdate(), interval 1 day)');
		delete $p{active_today};
    }

	if (exists $p{today}) {
		$self->add_where( \%p, 'datestart>=curdate() AND datestart<date_add(curdate(), interval 1 day)');
		delete $p{today};
    }

	$p{order_by} = 'datestart, title' if not defined $p{order_by};

	$self->SUPER::restore_where(%p);
}##restore_where


############################################################################
# Function: htmlField
############################################################################
sub htmlField	{	#08/07/01 3:05
############################################################################
	my $self = shift;
	my $attr = lc shift;
	my %CGIparams = @_;

	if ($attr eq 'duration') {
		my (%labels, @values);
		for my $i(0..6) {
			my $d = $i * 60;
			if ($d > 0) {
				push @values, $d;
				$labels{$d} = "$i:00";
			}
			$d += 30;
			push @values, $d;
			$labels{$d} = "$i:30";
        }
		return $self->SUPER::htmlField($attr,
			fieldtype => 'popup_menu',
			-values => \@values,
			-labels => \%labels,
			%CGIparams
			);
    }


	$self->SUPER::htmlField($attr);
}##htmlField



#find_next_day_event($date)

#find_prev_day_event($date)

#Find next or previous day where any event is. C<$date> is a string in
#C<DD.MM.YYYY>. If next event is found then the date is returned. If no more
#event is found then undef is returned.

############################################################################
sub find_next_day_event	{	#11/14/01 11:27
############################################################################
	my $self = shift;
    my $org_id = shift;
    my $dateref = shift;

    my $d = new ePortal::ThePersistent::DataType::Date(@$dateref);
    my $tp = new ePortal::ThePersistent::Support( SQL => "SELECT
        min(datestart) as min_date FROM Calendar
        WHERE datestart >= date_add(?, interval 1 day) AND org_id=?",
        Attributes => { min_date => {dtype => 'Date'}},
        );
    $tp->restore_where(bind => [$d->sql_value, $org_id]);
    $tp->restore_next;
    return $tp->min_date;
}##find_next_day_event

############################################################################
sub find_prev_day_event	{	#11/14/01 11:27
############################################################################
	my $self = shift;
    my $org_id = shift;
    my $dateref = shift;

    my $d = new ePortal::ThePersistent::DataType::Date(@$dateref);
    my $tp = new ePortal::ThePersistent::Support( SQL => "SELECT
        max(datestart) as max_date FROM Calendar
        WHERE datestart < ? AND org_id=?",
        Attributes => { max_date => {dtype => 'Date'}},
        );
    $tp->restore_where(bind => [$d->sql_value, $org_id]);
    $tp->restore_next;
    return $tp->max_date;
}##find_prev_day_event


############################################################################
sub parent  {   #06/17/02 11:10
############################################################################
    my $self = shift;

    my $C = new ePortal::App::Organizer::Organizer;
    $C->restore($self->org_id);
    return $C;
}##parent

1;

