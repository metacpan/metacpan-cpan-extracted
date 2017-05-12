use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

use WWW::Ohloh::API;

my $ohloh = WWW::Ohloh::API->new;

ok $ohloh, 'object creation';

$ohloh->set_api_key( 'mykey' );

is $ohloh->get_api_key => 'mykey', 'set/get_api_key';

$ohloh = WWW::Ohloh::API->new( api_key => 'myotherkey' );

is $ohloh->get_api_key => 'myotherkey', 'set api key from new()';


SKIP: {

    skip <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
online tests, to enable set the environment variable OHLOH_KEY to your api key
END_MSG

    $ohloh->set_api_key( $ENV{OHLOH_KEY} );
    ok $ohloh->get_account( id => 12933 );

}
