%#============================================================================
%# ePortal - WEB Based daily organizer
%# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
%#
%# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
%# This program is open source software
%#
%#
%#----------------------------------------------------------------------------
<%perl>
  # pseudo persistent session
  %gdata = ();

  # Parse cookie and create persistent session
  my $cookie = new Apache::Cookie($r);
  my %cookies = $cookie->parse;

  foreach (keys %cookies) {
    logline('debug', "Received cookie $_=".$cookies{$_}->value);
  }

  # clear session hash
  %session = ();
  my $session_id = $cookies{ePortal} ? $cookies{ePortal}->value() : undef;

  # try to restore new session
  if ( $session_id ) {
    my $datacount = $ePortal->dbh->selectrow_array("SELECT count(*) FROM sessions WHERE id=?", undef, $session_id);
    my $data = $ePortal->dbh->selectrow_array("SELECT a_session FROM sessions WHERE id=?", undef, $session_id);
    if ( $datacount != 0 ) {
      my $data_thaw = Storable::thaw($data);
      if ( ref($data_thaw) eq 'HASH' ) {
        %session = ( %{$data_thaw} );
      } else {  # Session data exists, but it is not a HASH
        $session_id = undef;
        $session{_new_session} = 1;
      }  
    } else {
      $session{_new_session} = 1;
    }
  }

  # absolutely new session
  if ( ! $session_id ) {  # new user
    $session_id = substr(Digest::MD5::md5_hex(Digest::MD5::md5_hex(time(). rand(). $$)), 0, 32);
    $session{_new_session} = 1;
  }
  $session{_session_id} = $session_id;

  if ( ! $cookies{ePortal} ) {
      my $cookie = new Apache::Cookie($r,
          -name=>'ePortal',
          -expires => 'Mon, 28-Dec-2099 00:00:00 GMT',
          -value=>$session{_session_id},
          -path => '/',);
      $cookie->bake;
      my $address = $r->get_remote_host;
      logline('debug', 'Sending session cookie. '.$cookie->as_string);
  }

  return $session{_session_id};
</%perl>
