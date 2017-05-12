%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
% if ($ErrorMessage or $GoodMessage) {
  <!--UdmComment-->
	<table border=0 width="100%">
		<tr><td>
	<hr size=1 align=center width="80%">
		<center><span class="errormessage"><% $ErrorMessage %></span></center>
% 	if ($ErrorMessage and $GoodMessage) {
	<hr size=1 align=center width="80%">
%		}
		<center><span class="goodmessage"><% $GoodMessage %></span></center>
	<hr size=1 align=center width="80%">
	</td></tr>
	</table>
  <!--/UdmComment-->
% }

%#============================================================================
<%args>
$ErrorMessage => undef
$GoodMessage => undef
</%args>


%#============================================================================
<%init>
	# —ообщени€ в переменных сессии.
	if ($session{ErrorMessage}) {
		$ErrorMessage .= '<br>' if ($ErrorMessage);
		$ErrorMessage .= $session{ErrorMessage};
		delete $session{ErrorMessage};
	}

	if ($session{GoodMessage}) {
		$GoodMessage .= '<br>' if ($GoodMessage);
		$GoodMessage .= $session{GoodMessage};
		delete $session{GoodMessage};
	}

  # ≈сли нет никаких сообщений то сразу отваливаем, чтобы не мешать.
  if ($ErrorMessage eq '' and $GoodMessage eq '') {
    return undef;
  };
</%init>
