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


package ePortal::App::SquidAcnt::SAurl_group;
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
    $p{Attributes}{redir_type} ||= {
            label => {rus => 'Действие', eng => 'Action'},
            dtype => 'VarChar',
            fieldtype => 'popup_menu',
            default => 'block_info',
            values => ['block_info','empty_html','white_img','black_img','custom','allow_local','allow_external'],
            labels => {
                block_info  => {rus => 'Блокировать: Стандартная страница', eng => 'Block: Standard page'},
                empty_html  => {rus => 'Блокировать: Пустая HTML страница', eng => 'Block: Empty HTML page'}, 
                white_img   => {rus => 'Блокировать: Белый рисунок', eng => 'Block: White image'}, 
                black_img   => {rus => 'Блокировать: Черный рисунок', eng => 'Block: Black image'}, 
                custom      => {rus => 'Блокировать: Другой URL', eng => 'Block: Custom URL'}, 
                allow_local => {rus => 'Пустить: Локальный адрес', eng => 'Allow: Local URL'}, 
                allow_external=> {rus => 'Пустить: Внешний адрес', eng => 'Allow: External URL'}, 
            },    
        };
    $p{Attributes}{redir_url} ||= {
        dtype => 'VarChar',
        size => 60,
        label => {rus => "Другой URL", eng => "Custom URL"},
        default => 'http://www.server.org/your_page.html',
    };

    $self->SUPER::initialize(%p);
}##initialize


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
# For recursive deletion of SAurl
sub children    {   #08/07/2003 2:54
############################################################################
    my $self = shift;
    
    my $st = new ePortal::App::SquidAcnt::SAurl();
    $st->restore_where(url_group_id => $self->id);

    return $st;
}##children

############################################################################
sub xacl_check_read {   #08/19/2003 12:59
############################################################################
    1;
}##xacl_check_read


1;
