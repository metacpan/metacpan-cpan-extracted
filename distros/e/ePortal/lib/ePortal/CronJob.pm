#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------


package ePortal::CronJob;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Support/;

    use ePortal::Utils;
    use ePortal::Global;


############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{title} ||= {
                label => {rus => "Файл задания", eng => "Job file"},
            };
    $p{Attributes}{memo} ||= {
                label => {rus => 'Описание', eng => 'Memo'},
                fieldtype => 'textarea',
            };
    $p{Attributes}{period} ||= {
                label => {rus => 'Частота исполнения', eng => 'Execution freq'},
                fieldtype => 'popup_menu',
                values => [qw /daily hourly 5 10 20 30 always/],
                labels => {
                    daily   => {rus => 'ежедневно', eng => 'every day'},
                    hourly  => {rus => 'каждый час', eng => 'every hour'},
                    always  => {rus => 'каждый раз', eng => 'every time'},
                    5       => {rus => 'каждые 5 мин.', eng => 'every 5 min'},
                    10      => {rus => 'каждые 10 мин.', eng => 'every 10 min'},
                    20      => {rus => 'каждые 20 мин.', eng => 'every 20 min'},
                    30      => {rus => 'каждые 30 мин.', eng => 'every 30 min'},
                },
                default => 'daily',
            };
    $p{Attributes}{lastrun} ||= {
                label => {rus => 'Последний старт', eng => 'Last start time'},
                dtype => 'DateTime',
            };
    $p{Attributes}{lastresult} ||= {
                label => {rus => 'Результат исполнения', eng => 'Last run result'},
                fieldtype => 'popup_menu',
                values => [qw /unknown no_work done failed running/],
                labels => {
                    unknown  => {rus => 'неизвестен', eng => 'unknown'},
                    no_work  => {rus => 'нечего делать', eng => 'no work'},
                    done     => {rus => 'выполнено',     eng => 'done'},
                    failed   => {rus => 'ошибка',     eng => 'failed'},
                    running  => {rus => 'работает',   eng => 'running'},
                },
                default => 'unknown',
            };
    $p{Attributes}{currentresult} ||= {
        type => 'Transient',
        description => 'Execution result of current job',
        default => 'unknown',
    };    
    $p{Attributes}{mailresults} ||= {
                label => {rus => 'Отправлять результат на email', eng => 'Send results to email'},
                fieldtype => 'popup_menu',
                values => [qw /never on_error on_success always /],
                labels => {
                    never       => {rus => 'никогда',    eng => 'never'},
                    on_error    => {rus => 'при ошибке', eng => 'on error'},
                    on_success  => {rus => 'при действии', eng => 'on action'},
                    always      => {rus => 'всегда',     eng => 'always'},
                },
                default => 'never',
            };
    $p{Attributes}{jobstatus} ||= {
                label => {rus => 'Состояние задания', eng => 'Job status'},
                fieldtype => 'popup_menu',
                values => [qw /enabled disabled/],
                labels => {
                    enabled  => {rus => 'включено',  eng => 'enabled'},
                    disabled => {rus => 'выключено', eng => 'disabled'},
                },
                default => 'disabled',
            };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{lastresulthtml} ||= {
                label => {rus => 'Результат исполнения в HTML', eng => 'Last result in HTML'},
                maxlength => 65000,
            };
    $p{Attributes}{jobserver} ||= {
        label => {rus => 'Имя сервера задач', eng => 'Job server name'},
    };
    $p{Attributes}{forcerun} ||= {
        dtype => 'YesNo',
        label => {rus => 'Форсировать запуск', eng => 'Force run next time'},
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

    # Check title
    unless ( $self->title ) {
        return pick_lang(rus => "Не указано наименование шаблона для исполнения",
            eng => 'No template name to execute');
    }

    undef;
}##validate


############################################################################
sub restore {   #05/06/2003 3:19
############################################################################
    my ($self, $id) = @_;

    my $result = $self->SUPER::restore($id);
    if (!$result) {
        $self->restore_where(where => 'title = ?', bind => [ $id ]);
        $result = $self->restore_next;
    }
    return $result;
}##restore


############################################################################
sub restore_where   {   #12/24/01 4:30
############################################################################
    my ($self, %p) = @_;

    # default ORDER BY clause
    $p{order_by} = 'title' if not defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


1;
