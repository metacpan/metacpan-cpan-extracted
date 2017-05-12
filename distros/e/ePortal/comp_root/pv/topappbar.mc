%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
%if ($ePortal::DEBUG) {
  <!-- start of pv/toappbar.mc ------------------------------------------- -->
%}
<table width="100%" cellpadding=0 cellspacing=0 border=0>
	<tr  bgcolor="#EEEEEE">
		<td width=150>
			<& /inset.mc, page => "/topappbar.mc", number => 1 &>
		</td>

		<td width="90%">
			<table width="100%" border=0 cellspacing=0 cellpadding=0>
				<tr>
					<td align="center" valign="middle" class="title">
						<b><% $ARGS{title} %></b>
					</td>
					<td align="right" valign="top" nowrap>
						<& .usernamebar &>
					</td>
				</tr>
				<tr>
					<td colspan=2 align=right valign=middle>
            <!-- buttons here -->
					</td>
				</tr>
			</table>
		</td>
	</tr>
  <& /empty_tr.mc, height => 3, bgcolor => "#6C7198", colspan => 3 &>
</table>
%if ($ePortal::DEBUG) {
  <!-- end of pv/toappbar.mc --------------------------------------------- -->
%}


%#=== @METAGS usernamebar =========================================================
<%def .usernamebar><%perl>
	return if ($m->base_comp->name =~ /logout.htm/);

	my ($login_url, $login_title);
	if ( $ePortal->username  ) {
		$login_url = "/logout.htm";
		$login_title = pick_lang(rus => "Разрегистрироваться", eng => "Logout");
	} else {
		$login_url = "/login.htm";
		$login_title = pick_lang(rus => "Зарегистрироваться", eng => "Login");
	}
</%perl>

	<b><% pick_lang(rus => "Пользователь", eng => "User&nbsp;name") %>:</b>
	<br>
	<a target="_top" href="<% $login_url %>" title="<% $login_title %>"><% $ePortal->ShortUserName %></a>
</%def>


<%filter>
s/^\s+//gmo;
</%filter>
