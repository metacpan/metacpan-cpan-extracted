#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::KakakuCom' );
}

diag( "Testing WebService::KakakuCom $WebService::KakakuCom::VERSION, Perl $], $^X" );
