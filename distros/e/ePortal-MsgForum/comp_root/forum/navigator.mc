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

<b>
  <a href="index.htm">
    <% pick_lang(rus => "Все форумы", eng => "List of forums") %></a>
% if ($ePortal->isAdmin) {
    &gt;&gt;
    <% plink(pick_lang(rus => "Новый форум", eng => "New forum"),
        -href => "forum_admin.htm?objid=0") %>
% }
</b>

% if ($forum) {
<b>
    &gt;&gt;
  <a href="<% href("topics.htm", forum_id => $forum->id) %>">
    <% $forum->Title |h %></a>

% if ($message) {
    &gt;&gt;
  <a href="<% href("view_msg.htm", msg_id => $message->id) %>">
    <% substr($message->Title, 0, 15).  '...' |h %></a>
% }

% if ($forum->xacl_check('xacl_post')) {
    &gt;&gt;
  <% img(src => '/images/MsgForum/msg.gif') %>
  <a href="<% href("compose.htm", forum_id => $forum->id) %>">
    <% pick_lang(rus => "Новая тема", eng => "New topic") %></a>
% }

</b>
<hr>
% }



%#=== @metags args =========================================================
<%args>
$forum => undef
$message => undef
</%args>
