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
   my $E = $ARGS{E};
</%perl>
<!--UdmComment-->
<& /message.mc, ErrorMessage => pick_lang(rus => "В доступе отказано", eng => "Access denied") &>

<div align="center">

<span class="memo">
<b><% pick_lang(rus => "Причина", eng => "Cause") %>:</b>
  <% $E->text %>
</span>
<br>

<span class="memo">
<b><% pick_lang(rus => "Объект", eng => "Object") %>:</b>
  <% ref($E->object) %>:<% eval{$E->object->id} %>
</span>
<br>

<span class="memo">
<b><% pick_lang(rus => "Вид операции", eng => "Operation") %>:</b>
  <% $E->{'-operation'} %>
</span>
<br>

<%perl>

</%perl>
<hr>
<% plink( pick_lang(rus => "Вернуться назад", eng => "Return back"),
  -href => "javascript:window.history.go(-1);" ) %>
</div>
<!--/UdmComment-->
