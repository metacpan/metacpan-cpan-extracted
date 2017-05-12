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
<%perl>
    my $section = $ARGS{section};

    my $app = $ePortal->Application( 'MsgForum' );
    if ( ! ref($app) ) {
      </%perl><& /message.mc, ErrorMessage => pick_lang(
          rus => "Приложение MsgForum не установлено",
          eng => "MsgForum application is not installed") &>
      <%perl>
      return;
    }

    # create the object with forums
    # but restore only first few forums !!!
    my $forum = $app->Forums;
    $forum->restore_where(limit_rows => 20);
</%perl>

<table width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <th class="smallfont">Название</th>
    <% empty_td(width=>2) %>
    <th class="smallfont">Тем</th>
    <% empty_td(width=>2) %>
    <th class="smallfont">Сообщений</th>
    <% empty_td(width=>2) %>
    <th class="smallfont" align="right">Последнее</th>
  </tr>
% my $counter = 0;
% while ($forum->restore_next) {
  <tr bgcolor="<% $counter++ %2? '#FFFFFF' : '#EEEEEE' %>">
    <td class="smallfont">
      <A href="<% href('/forum/topics.htm', forum_id => $forum->id) %>">
      <% $forum->Title %></a>
    </td>
    <% empty_td(width=>2) %>
    <td class="smallfont" align="center">
      <% $forum->topics %>
    </td>
    <% empty_td(width=>2) %>
    <td class="smallfont" align="center">
      <% $forum->messages %>
    </td>
    <% empty_td(width=>2) %>
    <td class="smallfont" align="right">
      <% $forum->last_message %>
    </td>
  </tr>
% }

</table>



%#=== @metags attr =========================================================
<%attr>
def_title => { rus => "Дискуссионные форумы", eng => "Discussion forums" }
def_width => "W"
def_url => "/forum/index.htm"
</%attr>



%#=== @METAGS Help ====================================================
<%method Help>
</%method>

