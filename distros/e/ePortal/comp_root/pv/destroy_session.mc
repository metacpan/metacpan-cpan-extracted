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
  my $new_session = $session{_new_session};
  my $session_id = $session{_session_id};
  foreach (keys %session) {
    delete $session{$_} if /^_/o;
  }


  if ( scalar %session ) {          # if something to save
    my $data = Storable::nfreeze(\%session);
    if ( $new_session ) {
      $ePortal->dbh->do("INSERT into sessions (id,a_session) VALUES(?,?)", undef,
        $session_id, $data);
    } else {
      $ePortal->dbh->do("UPDATE sessions SET a_session=? WHERE id=?", undef,
        $data, $session_id);
    }

  } else {                               # nothing to save.
    $ePortal->dbh->do("DELETE FROM sessions where id=?", undef, $session_id)
      if ! $new_session;
  }

  %session = ();
  %gdata = ();
</%perl>
%#=== @METAGS flush ====================================================
<%method flush><%perl>
  my $new_session = $session{_new_session};
  my $session_id = $session{_session_id};
  my %dummy_session = (%session); # copy %session

  foreach (keys %dummy_session) {
    delete $dummy_session{$_} if /^_/o;
  }


  if ( scalar %dummy_session ) {      # if something to save
    my $data = Storable::nfreeze(\%dummy_session);
    if ( $new_session ) {
      $ePortal->dbh->do("INSERT into sessions (id,a_session) VALUES(?,?)", undef,
        $session_id, $data);
      delete $session{_new_session};

    } else {
      $ePortal->dbh->do("UPDATE sessions SET a_session=? WHERE id=?", undef,
        $data, $session_id);
    }
  }

  %session = ();
  %gdata = ();
  
</%perl></%method>
