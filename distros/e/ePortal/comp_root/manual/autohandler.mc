%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------

% if ($r->uri =~ /index.htm$/) {
	<% $m->call_next %>

% } else {
	<p align="right">
	<% plink(pick_lang(rus => "К оглавлению", eng => "Table of contents"), -href => "index.htm") %>
	</p>
	<p>

  <% $m->call_next_filtered() %>

	<p align="right">
	<% plink(pick_lang(rus => "К оглавлению", eng => "Table of contents"), -href => "index.htm") %>
	</p>
% }


%#=== @metags attr =========================================================
<%attr>
Title => {rus => "Руководство по ePortal", eng => "ePortal manual"}
</%attr>
