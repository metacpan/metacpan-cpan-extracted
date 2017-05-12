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


package ePortal::App::SquidAcnt::SAgroup;
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
    $p{Attributes}{title} ||= {};
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{daily_limit} ||= {
            dtype => 'Number',
            label => {rus => 'Лимит на день', eng => 'Daily limit'},
    };
    $p{Attributes}{weekly_limit} ||= {
            dtype => 'Number',
            label => {rus => 'Лимит на неделю', eng => 'Weekly limit'},
    };
    $p{Attributes}{mon_limit} ||= {
            dtype => 'Number',
            label => {rus => 'Лимит на месяц', eng => 'Monthly limit'},
    };
    $p{Attributes}{daily_alert} ||= {
            dtype => 'Number',
            label => {rus => 'Порог предупреждения на день', eng => 'Daily threshold limit'},
    };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub validate    {   #07/06/00 2:35
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    unless ( $self->title ) {
        return pick_lang(rus => "Не указано наименование", eng => 'No name');
    }

    undef;
}##validate



############################################################################
sub restore_where   {   #12/24/01 4:02
############################################################################
    my ($self, %p) = @_;

    $p{order_by} = 'title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub parent  {   #04/09/02 1:31
############################################################################
    my $self = shift;
    return $ePortal->Application('SquidAcnt');
}##parent

############################################################################
sub delete  {   #09/02/2003 3:29
############################################################################
    my $self = shift;
    my $id = $self->id;

    my $result = $self->SUPER::delete;
    if ($result) {
        $result += $self->dbh->do("UPDATE SAuser SET group_id=NULL WHERE group_id=?", undef, $id);
    }
    return $result;    
    
}##delete

############################################################################
sub xacl_check_read {   #08/25/2003 3:16
############################################################################
    1;
}##xacl_check_read

1;
