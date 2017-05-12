%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<div align="<% $align %>">
<table border="0" cellspacing="0" cellpadding="0" bgcolor="#FFFFFF">
<tr>
  <& /empty_td.mc, width=>5 &>
<td bgcolor="#e6e4e9" valign="top" width="5" align="right">
  <% img(src => "$images_base/cur_lt.gif", align=>'top', hspace => 0, alt => '') %>
</td>
<td bgcolor="#e6e4e9" valign="top" nowrap align="left">
    <span style="font-size:9pt;font-weight:bold; color:#800000;text-decoration:none;">
    ::&nbsp;<% $title %>&nbsp;
    </span>
</td>
<td bgcolor="#e6e4e9" valign="top" width="5" align="left">
  <% img(src => "$images_base/cur_rt.gif", align=>'top', hspace => 0, alt => '') %>
</td>
<& /empty_td.mc, width=>5 &>
<td class="memo">&nbsp;<% $extra %></td>
</tr>
</table>

% if ($underline) {
<table width="<% $width %>" border="0" cellspacing="0" cellpadding="0">
<tr>
  <& /empty_td.mc, width=>5 &>
  <td height="2"  bgcolor="#e6e4e9"><% img(src => "$images_base/cur_2x2.gif", alt => '') %></td>
</tr>
</table>
% }
</div>
%#=== @METAGS args =========================================================
<%args>
$title
$width => '99%'
$underline => 1
$align => 'left'
$extra => undef
$images_base => '/images/ePortal'
</%args>
