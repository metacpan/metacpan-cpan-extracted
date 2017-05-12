%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.   All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<script language="Javascript">
//<--
var PopupMenu_<% shift @_ %> = [
% while(my $a = shift @_) {
	['<% $a %>', '<% shift @_ %>'],
% }
];
//-->
</script>

% if (! $gdata{PopupMenuInstalled}) {
%	 $gdata{PopupMenuInstalled} = 1;

<div id="PopupMenu" style="position:absolute;display:none;">
<table border=2 cellpadding=0 cellspacing=0
	onmouseover="show_popup_menu();"
	onmouseout="hide_popup_menu();"><tr><td>
	<table border=0 cellpadding=0 cellspacing=0 bgcolor="#CCCCCC"
		onmouseover="show_popup_menu();">

% for my $i (0 .. 9) {
<tr id="PopupMenuTR_<% $i %>"><td id="PopupMenuTD_<% $i %>"
	onmouseover="this.bgColor='yellow';"
	onmouseout="this.bgColor='transparent';"><a
	 id="PopupMenuA_<% $i %>"
	 href="" class="PopupMenu"><% $i %></a></td></tr>
% }

</table>
</td></tr></table>
</div>
% }
