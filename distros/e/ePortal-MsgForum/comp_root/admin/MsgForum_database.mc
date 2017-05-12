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
    table => 'MsgForum',
    SQL => qq{
        CREATE TABLE `MsgForum` (
          `id` int(11) NOT NULL auto_increment,
          `titleurl` decimal(2,0) NOT NULL default '0',
          `title` varchar(255) default NULL,
          `nickname` varchar(255) default NULL,
          `memo` varchar(255) default NULL,
          `keepdays` int(11) default NULL,
          `uid` varchar(64) default NULL,
          `xacl_read` varchar(64) default NULL,
          `xacl_post` varchar(64) default NULL,
          `xacl_reply` varchar(64) default NULL,
          `xacl_edit` varchar(64) default NULL,
          `xacl_delete` varchar(64) default NULL,
          `xacl_attach` varchar(64) default NULL,
          PRIMARY KEY  (`id`)
        )
    } &>


% foreach my $column (qw/allowreply allowedit gid_r gid_w gid_a all_r all_w all_a all_reg gid/) {
  <& ePortal_database.htm:drop_column,
      table => 'MsgForum',
      column => $column
      &>
% }


% foreach my $column (qw/xacl_read xacl_post xacl_reply xacl_edit xacl_delete/) {
  <& ePortal_database.htm:add_column,
      table => 'MsgForum',
      column => $column,
      spec => 'varchar(64) default NULL'
      &>
% }

% # 3.0
<& ePortal_database.htm:modify_column,
    table => 'MsgForum',
    column => 'keepdays',
    match => 'int\(11\)',
    spec => 'int(11) default NULL'
    &>

%# 3.6
  <& ePortal_database.htm:add_column,
      table => 'MsgForum',
      column => 'xacl_attach',
      spec => "varchar(64) default NULL"
      &>



<& ePortal_database.htm:table_exists,
    table => 'MsgItem',
    SQL => qq{
          CREATE TABLE `MsgItem` (
        `id` int(11) NOT NULL auto_increment,
        `titleurl` varchar(255) default NULL,
        `title` varchar(255) default NULL,
        `prev_id` int(11) default NULL,
        `msglevel` varchar(255) default NULL,
        `msgdate` datetime default NULL,
        `useraddress` varchar(64) default NULL,
        `fromuser` varchar(64) default NULL,
        `forum_id` int(11) default NULL,
        `picture` varchar(255) default NULL,
        `uid` varchar(64) default NULL,
        `body` text,
        `email_sent` tinyint(4) default '0',
        PRIMARY KEY  (`id`),
        KEY `prev_id` (`prev_id`,`msglevel`),
        KEY `forum_id` (`forum_id`,`prev_id`)
      )
    } &>

%# 3.0
% foreach my $column (qw/ gid gid_r gid_w gid_a all_r all_w all_a all_reg/) {
    <& ePortal_database.htm:drop_column,
        table => 'MsgItem',
        column => $column
        &>
% }

<& ePortal_database.htm:index_exists,
    table => 'MsgItem',
    index => 'prev_id',
    spec => '(`prev_id`,`msglevel`)'
    &>

<& ePortal_database.htm:index_exists,
    table => 'MsgItem',
    index => 'forum_id',
    spec => '(`forum_id`,`prev_id`)'
    &>

% # 3.0
% foreach my $column (qw/prev_id forum_id/) {
    <& ePortal_database.htm:modify_column,
        table => 'MsgItem',
        column => $column,
        match => 'int\(11\)',
        spec => 'int(11) default NULL'
        &>
% }

% # 3.2
  <& ePortal_database.htm:add_column,
      table => 'MsgItem',
      column => 'email_sent',
      spec => 'tinyint default 0',
      SQL => [
        'UPDATE MsgItem SET email_sent=1 WHERE email_sent=0 or email_sent is NULL'
      ],
      &>



<& ePortal_database.htm:table_exists,
    table => 'MsgSubscr',
    SQL => qq{
        CREATE TABLE `MsgSubscr` (
          `forum_id` int(11) NOT NULL default '0',
          `username` varchar(64) NOT NULL default '',
          PRIMARY KEY  (`forum_id`,`username`)
        )
    } &>

<%perl>
# 3.6 Lowercase username
if ( table_exists($gdata{app_dbh}, 'MsgForum') ) {
  $gdata{app_dbh}->do("UPDATE MsgForum SET uid=LOWER(uid)");
}
if ( table_exists($gdata{app_dbh}, 'MsgItem') ) {
  $gdata{app_dbh}->do("UPDATE MsgItem SET uid=LOWER(uid)");
  $gdata{app_dbh}->do("UPDATE MsgItem SET fromuser=LOWER(fromuser)");
}
if ( table_exists($gdata{app_dbh}, 'MsgSubscr') ) {
  $gdata{app_dbh}->do("UPDATE MsgSubscr SET username=LOWER(username)");
}
</%perl>




<& ePortal_database.htm:add_catalog, 
        nickname   => 'ePortal-MsgForum-list',
        parent_id  => 'ePortal',
        url        => '/forum/index.htm',
        title      => pick_lang(
               rus => 'Приложение - Дискуссионные форумы',
               eng => 'Application - Discussion forums'),
    &>


<& ePortal_database.htm:add_PageSection, component => 'forums.mc' &>
<& ePortal_database.htm:add_PageSection, component => 'forumnews.mc' &>
