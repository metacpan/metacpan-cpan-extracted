%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%# Attention !!!:
%#  redirect.mc is called after cleanup_request.
%#  no $dbh, no $ePortal exists at this time
%#
%#----------------------------------------------------------------------------
<%perl>

	# Add optional server:port and full path
  if ($location !~ m|^/|o and $location !~ m|://|o) {
    my $redir_path = ($ENV{SCRIPT_NAME} =~ m|^(.*)/|o)[0];    # current script_path
		$location = "$redir_path/$location";
	}
  if ($location !~ m|://|o) {
    my $redir_port = $ENV{SERVER_PORT};
    $redir_port = '' if $redir_port == 80;          # Don't need it on port 80
    $redir_port = ':' . $redir_port if $redir_port; # add :

    my $redir_server = $ENV{SERVER_NAME};
    $redir_server = 'http://' . $redir_server if $redir_server !~ /^https?:/o;

    $location = "$redir_server$redir_port$location";
	}

  $m->redirect($location);
  return;
</%perl>

<%args>
$location => "/index.htm"
</%args>
