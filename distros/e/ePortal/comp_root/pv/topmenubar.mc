%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<%init>
  my $setup_url = '<b>&middot;</b>';
  if ( $ePortal->isAdmin ) {
    $setup_url = img(src => '/images/ePortal/setup.gif', href => '/admin/topmenu.htm',
      title => pick_lang(rus => "Настройка верхней строки меню", eng => "Setup top menu bar") );
  }
</%init>
% if ($ePortal::DEBUG) {
  <!-- start of pv/topmenubar.mc ------------------------------------------ -->
% }
<table width="100%" cellpadding=0 cellspacing=0 border=0 bgcolor="#6C7198">
  <tr><td class="topmenu" valign="top">
    &nbsp;<% $setup_url %>&nbsp;
			<a class="topmenu" target="_top" href="/index.htm"><% pick_lang( rus=>"В начало", eng=>"Home") %></a>
		&nbsp;<b>&middot;</b>&nbsp;

%	foreach my $i (1..3) {
%		my ($tName, $tURL) = ($ePortal->Config("TopMenuItemName$i"), $ePortal->Config("TopMenuItemURL$i"));
%		if ($tName and $tURL) {
			<a class="topmenu" target="_top" href="<% $tURL %>"><% $tName %></a>
			&nbsp;<b>&middot;</b>&nbsp;
% } }

    <a class="topmenu" target="_top" href="/catalog/index.htm"><% pick_lang(rus=>"Каталог", eng => "Catalogue") %></a>
		&nbsp;<b>&middot;</b>&nbsp;
	</td>

  <td align="right" class="topmenu" valign="top">
		&nbsp;<b>&middot;</b>&nbsp;
%		if ( $ePortal->username ) {
			<a target="_top" href="/logout.htm" class="topmenu"><% pick_lang(rus=>"Разрегистрироваться", eng => "Logout") %></a>
%		} else {
			<a target="_top" href="/login.htm" class="topmenu"><% pick_lang(rus=>"Регистрация", eng => "Login") %></a>
%		}
		&nbsp;<b>&middot;</b>&nbsp;
	</td>
	</tr>
</table>
%if ($ePortal::DEBUG) {
  <!-- username: <% $ePortal->username ? $ePortal->username : 'guest' %> -->
  <!-- isAdmin: <% $ePortal->isAdmin ? 'true' : 'false' %> -->
  <!-- end of pv/topmenubar.mc ------------------------------------------- -->
%}

<%filter>
s/^\s+//gmo;
</%filter>
