%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#----------------------------------------------------------------------------
<%perl>
  my $username = $ARGS{username};
  my $fio = $ePortal->dbh->selectrow_array(
    "SELECT fullname FROM epUser WHERE username=?", undef, $username);
  $fio ||= $username;
</%perl>
<% $fio %>
