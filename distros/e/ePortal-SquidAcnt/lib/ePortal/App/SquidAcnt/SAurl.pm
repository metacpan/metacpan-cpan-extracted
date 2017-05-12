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


package ePortal::App::SquidAcnt::SAurl;
    use base qw/ePortal::ThePersistent::ParentACL/;
    our $VERSION = '4.2';

    use ePortal::Global;
    use ePortal::Utils;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'SquidAcnt';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {
            label => {rus => 'Слово', eng => 'Word' },
        };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{url_group_id} ||= {
            label => {rus => 'Группа блокировок', eng => 'Blocking group'},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => sub {
                my $self = shift;
                my $m = new ePortal::App::SquidAcnt::SAurl_group;
                my ($values, $labels) = $m->restore_all_hash();
#                unshift @{$values}, '';
#                $labels->{''} = '---';
                return ($values, $labels);
            }
        };
    $p{Attributes}{url_type} ||= {
            label => {rus => 'Тип', eng => 'Type'},
            fieldtype => 'popup_menu',
            default => 'domain_string',
            values => ['domain_string','domain_regex','path_string','path_regex', 'regex'],
            labels => {
                domain_string => {rus => "домен:строка", eng => "domain:string"},
                domain_regex  => {rus => "домен:regex", eng => "domain:regex"},
                path_string   => {rus => "путь:строка", eng => "path:string"},
                path_regex    => {rus => "путь:regex", eng => "path:regex"},
                regex         => 'regex',
            },    
    };

    $self->SUPER::initialize(%p);
}##initialize

############################################################################
sub validate    {   #08/07/2003 2:53
############################################################################
    my $self = shift;

    if (! $self->Title ) {
        return pick_lang(rus => "Не указано слово для URL", eng => "No URL title");
    }    

    if (! $self->url_group_id) {
        return pick_lang(rus => "Не указана группа блокировок", eng => "No blocking group");
    }    

    # lowercase domain name. Regex may contain somthing like \D
    $self->Title( lc $self->Title) if $self->url_type =~ /_string/;

    # check regex for validity
    if ($self->url_type =~ /regex/) {
        my $regex = $self->Title;
        eval { $regex =~ /$regex/ };
        if ($@) {
            return pick_lang(rus => "Неправильное регулярное выражение", eng => "Error in regular expression")
        }    
    }    

    return $self->SUPER::validate(@_);
}##validate

############################################################################
sub restore_where   {   #12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

    $p{order_by} = 'url_type, title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #04/09/02 1:31
############################################################################
    my $self = shift;
    return $ePortal->Application('SquidAcnt');
}##parent

############################################################################
sub xacl_check_read {   #08/19/2003 12:59
############################################################################
    1;
}##xacl_check_read

1;
