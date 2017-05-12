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


package ePortal::App::MsgForum::MsgItem;
    use base qw/ePortal::ThePersistent::Support/;
    our $VERSION = '4.2';

    use Carp;
    use ePortal::Global;
    use ePortal::epUser;
    use ePortal::Utils;
    use ePortal::Attachment;

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{DBISource} = 'MsgForum';
    $p{Attributes}{id} ||= {};
    $p{Attributes}{forum_id} ||= {
            dtype => 'Number',
            label => {rus => "Форум", eng => "Forum"},
            fieldtype => 'popup_menu',
            popup_menu => sub {
                my $self = shift;
                my $m = new ePortal::App::MsgForum::MsgForum;
                my ($values, $labels) = $m->restore_all_hash();
                push @{$values}, '';
                $labels->{''} = '---';
                return ($values, $labels);
            }
        };
    $p{Attributes}{prev_id} ||= {
            dtype => 'Number',
            label => 'Prev ID',
        };
    $p{Attributes}{msgdate} ||= {
            label => {rus => 'Дата сообщения', eng => 'Message date'},
            dtype => 'DateTime',
        };
    $p{Attributes}{title} ||= {
            label => {rus => 'Тема', eng => 'Subject'}, # Для edit
        };
    $p{Attributes}{titleurl} ||= {
            label => {rus => 'URL сообщения', eng => 'Message URL'},
            size => 50,
        };
    $p{Attributes}{body} ||= {
            maxlength => 65000,
            label => {rus => 'Текст сообщения', eng => 'Message text'},
            fieldtype => 'textarea',
            columns => 80,
            rows => 10,
        };
    $p{Attributes}{picture} ||= {
            label => {rus => 'Иконка', eng => 'Icon'},
        };
    $p{Attributes}{fromuser} ||= {
            label => {rus => 'Автор сообщения', eng => 'Author'},
            maxlength => 64,
        };
    $p{Attributes}{useraddress} ||= {
            maxlength => 64,
            label => "TCP/IP address",
        };
    $p{Attributes}{msglevel} ||= {
        dtype => 'Varchar',
        description => 'Indentation level for replies',
        };
    $p{Attributes}{email_sent} ||= {
        dtype => 'Number',
        default => 0,
        description => 'Notification about new message is sent',
        };
    $p{Attributes}{upload_file} ||= {};

    $self->SUPER::initialize(%p);
}##initialize



############################################################################
# Function: parent
# Description: Returns ThePersistent parent object
# Parameters: none
# Returns: MsgForum object
#
############################################################################
sub parent  {   #12/07/00 11:33
############################################################################
    my $self = shift;

    my $nb = new ePortal::App::MsgForum::MsgForum;
    if ($nb->restore($self->Forum_id)) {
        return $nb;
    } else {
        return undef;
    }
}##parent



############################################################################
# Function: validate
# Description: Проверка данных перед сохранением объекта
# Parameters: not null - проверка перед insert
# Returns: Строку с описанием ошибки или undef;
#
############################################################################
sub validate    {   #07.07.2000 12:46
############################################################################
    my $self = shift;
    my $beforeinsert = shift;

    # Простые проверки на наличие данных.
    unless ( $self->Title ) {
        return pick_lang(rus => 'Не указано наименование новости', eng => 'Please write a title');
    }

    unless ($self->forum_id) {
        return pick_lang(rus => 'Не указан форум для сообщения', eng => 'Forum not specified');
    }

    unless ($self->Body) {
        return pick_lang(rus => 'Вы же ничего не написали!', eng => 'You have wrote nothing!');
    }

    if ($self->prev_id) {
        my $m = new ePortal::App::MsgForum::MsgItem;
        $m->restore($self->prev_id);
        if ($self->Body eq $m->ReplyTo) {
            return pick_lang(rus => 'Вы же ничего не написали!', eng => 'You have wrote nothing!');
        }
    }

    undef;
}##validate


############################################################################
# Function: insert (overloaded)
# Description: Set some values to default
#
############################################################################
sub insert  {   #03/28/01 4:09
############################################################################
    my $self = shift;

    # These two function is read-only in MsgItem. Call SUPER.
    # These attributes are defined during import process.
    $self->SUPER::value('fromuser', $ePortal->username) unless $self->fromuser;
    $self->SUPER::value('msgdate', 'now') unless $self->msgdate;
    $self->SUPER::value('useraddress', $ePortal->r->connection->remote_ip);
    $self->SUPER::insert(@_);
}##insert

############################################################################
# Description: Some functions have to be read-only
############################################################################
sub FromUser{   shift->value('fromuser') }
sub MsgDate {   shift->value('msgdate') }



############################################################################
# Function: htmlValue (overloaded)
#
############################################################################
sub htmlValue   {   #05/04/01 1:14
############################################################################
    my $self = shift;
    my $attr = lc shift;

    if ($attr eq 'fromuser') {
        return $self->htmlValue_FromUser;
    }

    $self->SUPER::htmlValue($attr);
}##htmlValue



############################################################################
# Description: Читабельное имя пользователя, отправившего сообщение
#
############################################################################
sub htmlValue_FromUser  {   #05/04/01 2:26
############################################################################
    my $self = shift;
    my $username;
    my $user = new ePortal::epUser;

    if ($self->FromUser eq '') {
        $username = pick_lang(rus => 'Гость', eng => 'Guest');

    } elsif ($user->restore($self->FromUser)) {
        $username = $user->ShortName;

    } else {
        $username = $self->FromUser;
    }

    return CGI::span({-class => 'dlgfield'}, $username);
}##htmlValue_FromUser


############################################################################
sub htmlSave    {   #06/16/2003 3:49
############################################################################
    my $self = shift;
    my $result = $self->SUPER::htmlSave(@_);
    if ($result) {
        my $att = new ePortal::Attachment(obj => $self);
        $att->upload(r => $ePortal->r);
    }
    return $result;
}##htmlSave


############################################################################
# Description: Сформировать ответ на сообщение.
#  Делает подготовительную работу по формированию ответа на сообщение.
# Parameters: MsgItem id to reply to
# Returns: undef on error
#
############################################################################
sub ReplyTo {   #05/04/01 3:05
############################################################################
    my $self = shift;
    return join("\n", map({">$_"} split('\n', $self->body)));
}##ReplyTo



############################################################################
# Description: Replies count to this message
# Returns: number of replies or undef on error
#
############################################################################
sub Replies {   #05/07/01 11:37
############################################################################
    my $self = shift;
    my $reply_count = 0;

    # Считываем список всех ответов непосредственно на меня и
    # рекурсивно их опрашиваем.
    my $replies = new ePortal::App::MsgForum::MsgItem;
    $replies->restore_where(where => "prev_id=?", bind => [$self->id]);
    while($replies->restore_next) {
        $reply_count ++;
        $reply_count += $replies->Replies;
    }

    return $reply_count;
}##Replies




############################################################################
# Function: short_date
# Description: Message date/time in short format. If message date is equal to
#   today then only time returned. If the date is different then only
#   date part is returned
# Parameters: None
# Returns: Message date or time
#
############################################################################
sub short_date  {   #06/09/01 9:39
############################################################################
    my $self = shift;
    my ($d, $t) = split('\s+', $self->msgdate, 2);

    # calc today date
    my @dt = CORE::localtime;
    $dt[4] += 1;
    $dt[5] += 1900;
    my $today = sprintf ("%02d.%02d.%04d", (@dt)[3,4,5] );

    return ($d eq $today ? $t : $d);
}##short_date


############################################################################
sub delete  {   #11/12/02 10:12
############################################################################
    my $self = shift;
    my $result;

    if ($self->prev_id == 0) {  # this is start of topic !!!
                                # remove all replies
        my $m = new ePortal::App::MsgForum::MsgItem;
        $m->restore_where( prev_id => $self->id);
        while($m->restore_next) {
            $result += $m->delete;
        }
    }
    my $att = $self->Attachment;
    while($att) {
        $att->delete;
        last if ! $att->restore_next;
    }

    $result += $self->SUPER::delete();
    return $result;
}##delete



1;

