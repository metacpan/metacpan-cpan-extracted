
use Test;

plan tests => 6;

use Math::Business::SMA;

$sma = new Math::Business::SMA;

$sma->set_days(3);

$sma->insert( 3 ); ok !defined($sma->query);
$sma->insert( 8 ); ok !defined($sma->query);
$sma->insert( 9 ); ok($sma->query, ((3 + 8 + 9)/3.0) );
$sma->insert( 7 ); ok($sma->query, ((8 + 9 + 7)/3.0) );

my @s1 = (1,2,3,4,5,7,9,13);
my @s2 = (2,3,4,5,7,9,13,15);

$sma = new Math::Business::SMA(int @s1);
$sma->insert(@s1);

my $s1 = 0; $s1 += $_ for @s1;
my $a1 = $s1/@s1;

ok( $sma->query, $a1 );

my $s2 = 0; $s2 += $_ for @s2;
my $a2 = $s2/@s2;

$sma->insert($s2[-1]);

ok( $sma->query, $a2 );
