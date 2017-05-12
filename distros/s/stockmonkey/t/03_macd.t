
use Test;

plan tests => 5;

use Math::Business::MACD;

$macd = new Math::Business::MACD;

$macd->set_days(26, 12, 9);

my $m;

$macd->insert( 3 ) for 1 .. 25; ok( $m = $macd->query, undef );
$macd->insert( 3 );             ok( $m = $macd->query, 0 );

$macd->insert( 30 ); ok( $m = $macd->query > 0 );  # this is good enough for me really.

$macd->insert( 30 ) for 1 .. 6;
ok( $m = $macd->query_trig_ema, undef );

$macd->insert( 30 ) for 1 .. 6;
ok( $m = $macd->query_trig_ema > 0 ); # sorta the same deal
