#!perl -T

use Test::More tests => 1;
#use Test::More 'no_plan';

use WWW::Myspace;

SKIP: {
    my $myspace = new WWW::Myspace( "wmyw" . int(rand(100000)) . "wmyw",
            "afh" . int(rand(100000)) . "fds" );

    like( $myspace->error, qr/Login Failed.*username.*password/is,
            "site_login bad username/password handling" );
}
