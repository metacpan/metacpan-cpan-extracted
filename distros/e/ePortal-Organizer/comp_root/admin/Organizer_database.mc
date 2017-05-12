%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2003 Sergey Rusakov.  All rights reserved.
%# This program is free software; you can redistribute it
%# and/or modify it under the same terms as Perl itself.
%#
%#
%#----------------------------------------------------------------------------
<& ePortal_database.htm:table_exists,
    table => 'Organizer',
    SQL => qq{
          CREATE TABLE `Organizer` (
        `id` int(11) NOT NULL auto_increment,
        `Title` varchar(255) default NULL,
        `uid` varchar(64) default NULL,
        `xacl_read` varchar(64) default NULL,
        `xacl_write` varchar(64) default NULL,
        `xacl_admin` varchar(64) default NULL,
        `Private` tinyint(4) NOT NULL default '0',
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`)
      )
    } &>


<& ePortal_database.htm:table_exists,
    table => 'Category',
    SQL => qq{
          CREATE TABLE `Category` (
        `id` int(11) NOT NULL auto_increment,
        `title` varchar(255) default NULL,
        `org_id` int(11) NOT NULL default '0',
        PRIMARY KEY  (`id`),
        KEY `org_id` (`org_id`)
      )
    } &>


%#
%# @metags Calendar
%#
<& ePortal_database.htm:table_exists,
    table => 'Calendar',
    SQL => qq{
            CREATE TABLE `Calendar` (
            `id` int(11) NOT NULL auto_increment,
            `org_id` int(11) default '0',
            `category_id` int(11) default '0',
            `title` varchar(255) default NULL,
            `datestart` datetime default NULL,
            `duration` int(11) default NULL,
            `memo` text,
            `ts` timestamp(14) NOT NULL,
            PRIMARY KEY  (`id`),
            KEY `org_id` (`org_id`,`category_id`)
          )
    }&>

% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Calendar',
    column => 'id',
    match => 'auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Calendar',
    column => 'duration',
    match => 'int\(11\)',
    spec => 'int(11) default NULL',
    &>
%# 3.0
<& ePortal_database.htm:add_column, table => 'Calendar', column => 'org_id',
          spec => "int(11) NULL default '0'" &>
<& ePortal_database.htm:drop_column, table => 'Calendar', column => 'lastmodified' &>
<& ePortal_database.htm:add_column,  table => 'Calendar', column => 'ts', spec => 'timestamp(14) NOT NULL' &>

%# 3.0
<& ePortal_database.htm:add_column, table => 'Calendar', column => 'category_id',
          spec => "int(11) NULL default '0'" &>
%# 3.0
<& ePortal_database.htm:index_exists, table => 'Calendar', index => 'org_id',
          spec => '(`org_id`,`category_id`)' &>



%#
%# @metags Contact
%#
<& ePortal_database.htm:table_exists,
    table => 'Contact',
    SQL => qq{
            CREATE TABLE `Contact` (
          `id` int(11) NOT NULL auto_increment,
          `org_id` int(11) default '0',
          `category_id` int(11) default '0',
          `job` varchar(255) default NULL,
          `title` varchar(255) default NULL,
          `addr_w` varchar(255) default NULL,
          `addr_h` varchar(255) default NULL,
          `email` varchar(255) default NULL,
          `phone_w` varchar(255) default NULL,
          `company` varchar(255) default NULL,
          `phone_h` varchar(255) default NULL,
          `ts` timestamp(14) NOT NULL,
          `memo` text,
          PRIMARY KEY  (`id`),
          KEY `org_id` (`org_id`,`category_id`)
        )
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Contact',
    column => 'id',
    match => 'auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
%# 3.0
<& ePortal_database.htm:add_column, table => 'Contact', column => 'org_id',
          spec => "int(11) NULL default '0'" &>
<& ePortal_database.htm:drop_column, table => 'Contact', column => 'lastmodified' &>
<& ePortal_database.htm:add_column,  table => 'Contact', column => 'ts', spec => 'timestamp(14) NOT NULL' &>

%# 3.0
<& ePortal_database.htm:add_column, table => 'Contact', column => 'category_id',
          spec => "int(11) NULL default '0'" &>
%# 3.0
<& ePortal_database.htm:index_exists, table => 'Contact', index => 'org_id',
          spec => '(`org_id`,`category_id`)' &>





%#
%# @metags Notepad =========================================================
%#
<& ePortal_database.htm:table_exists,
    table => 'Notepad',
    SQL => qq{
        CREATE TABLE `Notepad` (
          `id` int(11) NOT NULL auto_increment,
          `org_id` int(11) default '0',
          `category_id` int(11) default '0',
          `title` varchar(255) default NULL,
          `ts` timestamp(14) NOT NULL,
          `memo` text,
          PRIMARY KEY  (`id`),
          KEY `org_id` (`org_id`,`category_id`)
        )
    } &>

% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Notepad',
    column => 'id',
    match => 'auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
% # 3.0
<& ePortal_database.htm:drop_column, table => 'Notepad', column => 'lastmodified' &>
<& ePortal_database.htm:add_column,  table => 'Notepad', column => 'ts', spec => 'timestamp(14) NOT NULL' &>

%# 3.0
<& ePortal_database.htm:index_exists, table => 'Notepad', index => 'org_id',
          spec => '(`org_id`,`category_id`)' &>




%#
%# @metags ToDo
%#
<& ePortal_database.htm:table_exists,
    table => 'ToDo',
    SQL => qq{
            CREATE TABLE `ToDo` (
          `id` int(11) NOT NULL auto_increment,
          `org_id` int(11) default '0',
          `category_id` int(11) default '0',
          `title` varchar(255) default NULL,
          `status` varchar(16) default NULL,
          `datecompleted` date default NULL,
          `datestart` date default NULL,
          `dateend` date default NULL,
          `priority` decimal(2,0) default NULL,
          `ts` timestamp(14) NOT NULL,
          `memo` text,
          PRIMARY KEY  (`id`)
        )
    } &>

% # 3.0
<& ePortal_database.htm:modify_column, table => 'ToDo', column => 'id',
    match => 'auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
%# 3.0
<& ePortal_database.htm:add_column, table => 'ToDo', column => 'org_id',
          spec => "int(11) NULL default '0'" &>
% # 3.0
<& ePortal_database.htm:drop_column, table => 'ToDo', column => 'lastmodified' &>
<& ePortal_database.htm:add_column,  table => 'ToDo', column => 'ts', spec => 'timestamp(14) NOT NULL' &>



%# 3.0
<& ePortal_database.htm:add_column, table => 'ToDo', column => 'category_id',
          spec => "int(11) NULL default '0'" &>

%# 3.0
<& ePortal_database.htm:index_exists, table => 'ToDo', index => 'org_id',
          spec => '(`org_id`,`category_id`)' &>


%#
%# @metags Anniversary
%#
<& ePortal_database.htm:table_exists,
    table => 'Anniversary',
    SQL => qq{
          CREATE TABLE `Anniversary` (
          `id` int(11) NOT NULL auto_increment,
          `Title` text default NULL,
          `org_id` int(11) NOT NULL default '0',
          `an_day` tinyint(4) default NULL,
          `an_month` tinyint(4) default NULL,
          `an_year` smallint(6) default NULL,
          `category_id` int(11) default NULL,
          PRIMARY KEY  (`id`),
          KEY `org_id` (`org_id`,`an_month`,`an_day`)
          )
    } &>

<%perl>
# 3.6 Lowercase username
if ( table_exists($gdata{app_dbh}, 'Organizer') ) {
  $gdata{app_dbh}->do("UPDATE Organizer SET uid=LOWER(uid)");
}
</%perl>




<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-organizer',
        title      => pick_lang(
               rus => "Органайзер",
               eng => "Organizer"),
        recordtype => 'group',
        priority   => 2,
        parent_id  => 'ePortal',
        memo       => pick_lang(
               rus => "Персональный органайзер",
               eng => "Personal Organizer"),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-org-notepad',
        title      => pick_lang(
               rus => 'Записная книжка',
               eng => "Notepad"),
        url        => '/Organizer/memo_list.htm',
        parent_id  => 'ePortal-organizer',
        memo       => pick_lang(
               rus => "Персональная записная книжка с возможностью поиска",
               eng => "Personal searchable notepad"),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-org-address',
        title      => pick_lang(
               rus => 'Адреса и контакты',
               eng => "Addresses and contacts"),
        url        => '/Organizer/cont_list.htm',
        parent_id  => 'ePortal-organizer',
        memo       => pick_lang(
               rus => "Ваши адреса и контакты",
               eng => "Your addresses and contacts"),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-org-calendar',
        title      => pick_lang(
               rus => 'Ежедневник',
               eng => "Dairy"),
        url        => '/Organizer/cal_dairy.htm',
        parent_id  => 'ePortal-organizer',
        memo       => pick_lang(
               rus => "Персональный ежедневник с напоминанием о наступлении события",
               eng => "Your dairy with a reminder"),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-org-todo',
        title      => pick_lang(
               rus => 'Список дел',
               eng => "TO DO list"),
        url        => '/Organizer/todo_list.htm',
        parent_id  => 'ePortal-organizer',
        memo       => pick_lang(
               rus => "Список Ваших дел",
               eng => "A list of your tasks to do later"),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-org-ann',
        title      => pick_lang(
               rus => 'Даты и годовщины',
               eng => "Anniversaries list"),
        url        => '/Organizer/ann_list.htm',
        parent_id  => 'ePortal-organizer',
        memo       => pick_lang(
               rus => "Дни рождения, даты, праздники",
               eng => "A list of your anniversaries"),
    &>


<& ePortal_database.htm:add_PageSection, component => 'Organizer.mc' &>
<& ePortal_database.htm:add_PageSection, component => 'Organizer_ann.mc' &>
<& ePortal_database.htm:add_PageSection, component => 'Organizer_todo.mc' &>
