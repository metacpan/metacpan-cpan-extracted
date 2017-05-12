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
    my $username = $ARGS{username};
    my $savepassword = $ARGS{savepassword};

    my $cookie;

    if (defined $username) {
        my $remoteip = $r->get_remote_host;
        my $md5hash = Digest::MD5::md5_hex('13', $username, $remoteip);
        my $ticket = join(":", $username, $remoteip, $md5hash );

        $cookie = new Apache::Cookie( $r, -name => 'ePortal_auth',
                $savepassword ? (-expires => 'Mon, 28-Dec-2099 00:00:00 GMT') : (),
                -value => $ticket, -path => '/',);
    } else {
        $cookie = new Apache::Cookie($r, -name=>'ePortal_auth',
            -expires => 'Mon, 21-May-1971 00:00:00 GMT',
            -value => "", -path => '/',);
    }
    logline('debug', "Sending cookie ". $cookie->as_string);
    $cookie->bake;
    return undef;
</%perl>
