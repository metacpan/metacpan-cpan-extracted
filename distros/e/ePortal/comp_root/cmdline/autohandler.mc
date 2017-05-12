%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
% my %args = $m->request_args;
<table width="100%" border="0" bgcolor="#C2CDFA">
  <tr><td>
    ePortal v.<% $ePortal::Server::VERSION %>,
    CronJob name: <b><% $args{job}->Title |h %></b>
  </td></tr>
</table>

<% $m->call_next %>

<%perl>
  $ARGS{job}->CurrentResult('no_work') if $ARGS{job}->CurrentResult eq 'unknown';
</%perl>
<table width="100%" border="0" bgcolor="#C2CDFA">
  <tr><td>
    <% pick_lang(
        rus => "Результат исполнения задания:",
        eng => "Job execution result:") %> <b><% $ARGS{job}->CurrentResult %></b>
  </td></tr>
</table>

%#=== @METAGS flags =========================================================
<%flags>
inherit => undef
</%flags>

%#=== @METAGS once =========================================================
<%once>
use ePortal::Global;
use ePortal::Utils;
%session = ();
CGI::autoEscape(0);
</%once>

