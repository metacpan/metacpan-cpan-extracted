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
    table => 'Client',
    SQL => qq{
        CREATE TABLE `Client` (
        `id` int(11) NOT NULL auto_increment,
        `dept_id` int(11) NOT NULL default '0',
        `position` varchar(255) default NULL,
        `rank` int(2) unsigned default '5',
        `title` varchar(255) default NULL,
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`),
        KEY `dept_id` (`dept_id`,`rank`,`position`)
        )
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Client',
    column => 'id',
    match => 'auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Client',
    column => 'dept_id',
    match => 'int\(11\)',
    spec => "int(11) NOT NULL default '0'",
    &>



<& ePortal_database.htm:table_exists,
    table => 'Department',
    SQL => qq{
        CREATE TABLE `Department` (
        `id` int(11) NOT NULL auto_increment,
        `parent_id` int(11) NOT NULL default '0',
        `title` varchar(255) NOT NULL default '',
        `dept_code` varchar(32) default NULL,
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`),
        KEY `INDX_PARENT` (`parent_id`,`title`)
        ) COMMENT='Справочник подразделений'
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Department',
    column => 'id',
    match => '11.*auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Department',
    column => 'parent_id',
    match => 'int\(11\)',
    spec => "int(11) NOT NULL default '0'",
    &>


<& ePortal_database.htm:table_exists,
    table => 'Helper',
    SQL => qq{
        CREATE TABLE `Helper` (
        `id` int(11) NOT NULL auto_increment,
        `code` varchar(16) default NULL,
        `title` varchar(255) default NULL,
        PRIMARY KEY  (`id`),
        UNIQUE KEY `uni_title` (`code`,`title`)
        ) COMMENT='Справочник быстрого ввода повторяющихся значений'
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Helper',
    column => 'id',
    match => '11.*auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>



<& ePortal_database.htm:table_exists,
    table => 'Phone',
    SQL => qq{
        CREATE TABLE `Phone` (
        `id` int(11) NOT NULL auto_increment,
        `type_id` int(11) NOT NULL default '0',
        `client_id` int(11) NOT NULL default '0',
        `title` varchar(255) default NULL,
        PRIMARY KEY  (`id`),
        KEY `CLIENT_ID` (`client_id`)
        ) COMMENT='Справочник номеров телефонов'
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Phone',
    column => 'id',
    match => '11.*auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Phone',
    column => 'type_id',
    match => 'int\(11\)',
    spec => "int(11) NOT NULL default '0'",
    &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'Phone',
    column => 'client_id',
    match => 'int\(11\)',
    spec => "int(11) NOT NULL default '0'",
    &>



<& ePortal_database.htm:table_exists,
    table => 'PhoneMemo',
    SQL => qq{
        CREATE TABLE `PhoneMemo` (
        `id` int(11) NOT NULL auto_increment,
        `client_id` int(11) default '0',
        `dept_id` int(11) default '0',
        `user_name` varchar(64) default NULL,
        `private` tinyint(1) unsigned NOT NULL default '1',
        `title` text NOT NULL default '',
        `ts` timestamp(14) NOT NULL,
        PRIMARY KEY  (`id`),
        KEY `CLIENT_ID` (`client_id`)
        )
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'PhoneMemo',
    column => 'id',
    match => '11.*auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>
% # 3.0
% foreach (qw/client_id dept_id/) {
<& ePortal_database.htm:modify_column,
    table => 'PhoneMemo',
    column => $_,
    match => 'int\(11\)',
    spec => "int(11) default '0'",
    &>
% }

<& ePortal_database.htm:table_exists,
    table => 'PhoneType',
    SQL => qq{
        CREATE TABLE `PhoneType` (
        `id` int(11) NOT NULL auto_increment,
        `format` varchar(255) default NULL,
        `title` varchar(255) default NULL,
        PRIMARY KEY  (`id`)
        )
    } &>
% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'PhoneType',
    column => 'id',
    match => '11.*auto_incr',
    spec => 'int(11) NOT NULL auto_increment',
    &>

<& ePortal_database.htm:default_data,
    table => 'PhoneType',
    SQL_ary => [
      qq{INSERT INTO PhoneType(title,format) VALUES('Вн.|Int', '##-##') },
      qq{INSERT INTO PhoneType(title,format) VALUES('ГТС.|Ext', '##-##-##') },
      qq{INSERT INTO PhoneType(title,format) VALUES('Приемная|Secretary', '##-##') },
      qq{INSERT INTO PhoneType(title,format) VALUES('Приемная ГТС|Secretary ext', '##-##-##') },
      qq{INSERT INTO PhoneType(title,format) VALUES('Факс|Fax', '##-##-##') },
    ] &>

<%perl>
# 3.6 Lowercase username
if ( table_exists($gdata{app_dbh}, 'PhoneMemo') ) {
  $gdata{app_dbh}->do("UPDATE PhoneMemo SET user_name=LOWER(user_name) WHERE private=1");
}
</%perl>



<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-OffPhones-link',
        parent_id  => 'ePortal',
        url        => '/app/OffPhones/index.htm',
        title      => pick_lang(
               rus => 'Приложение - телефонный справочник',
               eng => 'Application - phones directory'),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-OffPhones',
        parent_id  => 'ePortal',
        recordtype => 'group',
        title      => pick_lang(
               rus => 'Тел.справочник',
               eng => 'Phones'),
        memo       => pick_lang(
               rus => 'Иерархический телефонный справочник',
               eng => 'Hierarchical phones directory'),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-OffPhones-phtype',
        parent_id  => 'ePortal-OffPhones',
        url        => '/app/OffPhones/pt_list.htm',
        title      => pick_lang(
               rus => 'Редактор типов телефонов',
               eng => 'Phone type editor'),
    &>
<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-OffPhones-memos',
        parent_id  => 'ePortal-OffPhones',
        url        => '/app/OffPhones/memo_list.htm',
        title      => pick_lang(
               rus => 'Список замечаний от пользователей',
               eng => "User's memos"),
    &>



<& ePortal_database.htm:add_PageSection, component => 'OffPhones.mc' &>

