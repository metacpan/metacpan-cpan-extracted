%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<%perl>
  my %args = $m->request_args;

#
#=== Default navigator ======================================================
#

my %NAV = (
  title => pick_lang(rus => "Страница Администратора: ", eng => "Admin's home: "),
  description => pick_lang(rus => 'К главной странице настройки ePortal.', eng => 'ePortal setup home page'),
  url => '/admin/index.htm',
  items => [ qw/ users groups other/ ],

  users => {
    title => pick_lang(rus => 'Пользователи', eng => 'Users'),
    description => pick_lang(rus => 'Работа с пользователями ePortal', eng => 'Administer users of ePortal'),
    items => [qw/users_list user_new/],
  },
  users_list => {
    title => pick_lang(rus => 'Список', eng => 'List'),
    description => pick_lang(rus => 'Список пользователей', eng => 'List of users'),
    url => '/admin/users_list.htm',
  },
  user_new => {
    title => pick_lang(rus => 'Новый пользователь', eng => 'New user'),
    description => pick_lang(rus => 'Новый пользователь', eng => 'New user'),
    url => '/admin/users_edit.htm?objid=0',
  },

  groups => {
    title => pick_lang(rus => 'Группы пользователей', eng => 'Groups of users'),
    description => pick_lang(rus => 'Работа с группами пользователей ePortal', eng => 'Administer groups of users of ePortal'),
    items => [qw/groups_list group_new/],
  },
  groups_list => {
    title => pick_lang(rus => 'Список', eng => 'List'),
    description => pick_lang(rus => 'Список групп пользователей', eng => 'List of groups of users'),
    url => '/admin/groups_list.htm',
  },
  group_new => {
    title => pick_lang(rus => 'Новая группа', eng => 'New group'),
    description => pick_lang(rus => 'Новая группа пользователей', eng => 'New group of users'),
    url => '/admin/groups_edit.htm?objid=0',
  },

  other => {
    title => pick_lang(rus => 'Прочее', eng => 'Other'),
    description => pick_lang(rus => 'Прочие команды администрирования', eng => 'Other administrative tasks'),
    items => [qw/CronJob_list statistics/],
  },
  CronJob_list => {
    title => pick_lang(rus => 'Периодические задания', eng => 'Periodic jobs'),
    description => pick_lang(rus => 'Список периодических заданий к исполнению', eng => 'List of periodic jobs'),
    url => '/admin/CronJob_list.htm',
  },
  statistics => {
    title => pick_lang(rus => 'Статистика', eng => 'Statistics'),
    description => pick_lang(rus => 'Статистика работы ePortal сервера', eng => 'Statistics of ePortal'),
    url => '/admin/statistics.htm',
  },
  %ARGS);
</%perl>

<& /navigator.mc, %NAV &>

