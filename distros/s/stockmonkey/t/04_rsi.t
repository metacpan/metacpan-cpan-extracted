
use Test;
use strict;
use Math::Business::RSI;

my $rsi = new Math::Business::RSI;
   $rsi->set_days(14);
   $rsi->set_cutler;
   # NOTE: todd's examples use Cuttler's RSI
   # (see: http://en.wikipedia.org/wiki/Relative_Strength_Index#Cutler.27s_RSI)

my @todd_litteken = qw(
    46.1250 47.1250 46.4375 46.9375 44.9375 44.2500 44.6250 45.7500 47.8125 47.5625
    47.0000 44.5625 46.3125 47.6875 46.6875 45.6875 43.0625 43.5625 44.8750 43.6875
);
my @orig = @todd_litteken;

my @RSI_todd = qw( 51.7787 48.4771 41.0734 42.8634 47.3818 43.9921 );

plan tests => 10;

$rsi->insert(splice @todd_litteken, 0, 14);
ok( $rsi->query, undef );

$rsi->insert(shift @todd_litteken);
ok( sprintf('%0.4f', $rsi->query), sprintf('%0.4f', shift @RSI_todd) );

# NOTE: todd's original spreadsheet uses =((F16*13)+D17)/14 to calculate the
# average in the next period...  I believe he meant =(F16 - D3/14 + D17/14) I
# calculated that by hand and got 45.4545

$rsi->insert(shift @todd_litteken);
ok( sprintf('%0.4f', $rsi->query), sprintf('%0.4f', '45.4545') );

######### The EMA RSI

$rsi->set_standard;
$rsi->insert(splice @orig, 0, 14);
ok( $rsi->query, undef );

# NOTE: I then computed (using his spreadsheet) the 14-day ema version
my @paul = qw( 48.6989 42.8212 31.3579 35.1721 44.5110 38.6921 );

while( @paul ) {
    $rsi->insert(shift @orig);
    ok( sprintf('%0.4f', $rsi->query), sprintf('%0.4f', shift @paul) );
}
