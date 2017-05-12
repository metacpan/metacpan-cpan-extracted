#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use WWW::Coderwall;

BEGIN {
    my $cw      = new_ok( 'WWW::Coderwall' );
    my $user    = new_ok( 'WWW::Coderwall::User' );    

    like( $cw->http_agent_name, qr/WWW::Coderwall\/\d+\.\d+$/, 
        'Default http_agent_name is WWW::Coderwall/#.###'
    );
    isa_ok( $cw->http_agent, 'LWP::UserAgent' );
    can_ok( $cw, qw( get_user _call_api ));
}

done_testing;
