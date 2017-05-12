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
# See http://graphica.newmail.ru/dates.html for BirthdayMillenium dates
# ------------------------------------------------------------------------

package ePortal::App::Organizer::Anniversary;
    our $VERSION = '4.2';
    use base qw/ePortal::ThePersistent::ParentACL/;

    use ePortal::Utils;
    use ePortal::Global;
    use Error qw/:try/;
    use ePortal::Exception;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my $self = shift;

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
    $p{Attributes}{an_day} ||= {
            dtype => 'Number',
            size => 2,
            label => { rus => 'День', eng => 'Day'},
            default => 0,
        };
    $p{Attributes}{an_month} ||= {
            dtype => 'Number',
            size => 2,
            label => { rus => 'Месяц', eng => 'Month'},
            fieldtype => 'popup_menu',
            values => [1..12],
            default => 1,
            labels => {
                        1 => { rus =>  "январь", eng => "January" },
                        2 => { rus =>  "февраль", eng => "February" },
                        3 => { rus =>  "март", eng => "March"},
                        4 => { rus =>  "апрель", eng => "April"},
                        5 => { rus =>  "май", eng => "May" },
                        6 => { rus =>  "июнь", eng => "June" },
                        7 => { rus =>  "июль", eng => "July" },
                        8 => { rus =>  "август", eng => "August" },
                        9 => { rus =>  "сентябрь", eng => "September"},
                        10 => { rus =>  "октябрь", eng => "Oktober" },
                        11 => { rus =>  "ноябрь", eng => "November" },
                        12 => { rus =>  "декабрь", eng => "December"},
                        },
        };
    $p{Attributes}{an_year} ||= {
            dtype => 'Number',
            size => 4,
            label => { rus => 'Год', eng => 'Year'},
            default => 0,
        };
    $p{Attributes}{title} ||= {
            label => {rus => 'Наименование', eng => 'Name'},
            size  => 40,
            maxlength => 65000,
            dtype => 'VarChar',
        };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
# Description: Validate the objects data
# Returns: Error string or undef
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    if ($self->org_id == 0) {
        throw ePortal::Exception::DataNotValid(
            -text => pick_lang(rus => "Не указан Органайзер", eng => "Unknown Organizer"));
    }

    if ($self->an_day <= 0 or $self->an_day>31 ) {
        throw ePortal::Exception::DataNotValid(
            -text => pick_lang(rus => "Неправильно указан день события", eng => "Day of month is invalid"));
    }
    if ($self->an_month <= 0 or $self->an_month>12 ) {
        throw ePortal::Exception::DataNotValid(
            -text => pick_lang(rus => "Неправильно указан месяц события", eng => "Month is invalid"));
    }

    return $self->SUPER::validate($beforeinsert);
}##validate


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # parent_id cannot be 0, it may be NULL
    $p{org_id} = undef if exists $p{org_id} and $p{org_id} == 0;

    # default ORDER BY clause
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
