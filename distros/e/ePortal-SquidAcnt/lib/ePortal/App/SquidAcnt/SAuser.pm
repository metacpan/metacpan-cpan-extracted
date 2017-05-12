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


package ePortal::App::SquidAcnt::SAuser;
    use base qw/ePortal::ThePersistent::ParentACL/;
    our $VERSION = '4.2';

	use ePortal::Global;
	use ePortal::Utils;

############################################################################
sub initialize	{	#05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'SquidAcnt';

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {};
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{group_id} ||= {
            label => {rus => 'Группа пользователей', eng => 'Group of users'},
            dtype => 'Number',
            fieldtype => 'popup_menu',
            popup_menu => sub {
                my $self = shift;
                my $m = new ePortal::App::SquidAcnt::SAgroup;
                my ($values, $labels) = $m->restore_all_hash();
                unshift @{$values}, '';
                $labels->{''} = '---';
                return ($values, $labels);
            }
        };
    $p{Attributes}{login_name} ||= {
            label => {rus => 'Имя входа на прокси-сервер', eng => 'Proxy login name'},
    };
    $p{Attributes}{address} ||= {
            label => {rus => 'TCP/IP адрес клиента', eng => 'TCP/IP address of client'},
    };
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
    $p{Attributes}{blocked} ||= {
            dtype => 'Number',
            fieldtype => 'YesNo',
            label => {rus => 'Блокирован из-за прев.лимита', eng => 'Blocked due to limit exceed'},
    };
    $p{Attributes}{end_date} ||= {
            dtype => 'Date',
            label => {rus => 'Срок действия', eng => 'Expiration date'},
    };

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub validate	{	#07/06/00 2:35
############################################################################
	my $self = shift;
	my $beforeinsert = shift;

    # Validate tcpip address
    if ($self->address eq '') {
        return pick_lang(rus => "Не указан TCP/IP адрес клиента", eng => "No TCP/IP address given");
    } else {
        my @i = split('\.', $self->address);
        return pick_lang(rus => "Неправильный адрес TCP/IP", eng => "TCP/IP address not valid")
            if @i != 4;
        foreach (@i) {
            return pick_lang(rus => "Неправильный адрес TCP/IP", eng => "TCP/IP address not valid")
                if $_ < 0 or $_ > 255;
        }
    }

    return $self->SUPER::validate($beforeinsert);
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
    return $ePortal->Application('SquidAcnt');
}##parent

############################################################################
sub delete  {   #09/02/2003 3:27
############################################################################
    my $self = shift;
    my $id = $self->id;

    my $result = $self->SUPER::delete;
    if ($result) {
        $result += $self->dbh->do("DELETE FROM SAtraf WHERE user_id=?", undef, $id);
    }
    return $result;    
}##delete

############################################################################
sub xacl_check_read {   #08/25/2003 3:16
############################################################################
    1;
}##xacl_check_read

1;
