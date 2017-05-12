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
<% $m->call_next %>
<div align="right">
<& /statistics.mc, id => 'ePortal-MsgForum-list', image => 0 &>
</div>

%#=== @metags attr =========================================================
<%attr>
Title => {rus => "Дискуссионные форумы", eng => "Discussion forums"}
Application => 'MsgForum'
</%attr>

