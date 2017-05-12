use Test::More tests => 12;

use_ok('Tie::NetAddr::IP');

my $count = 1;

my %Test;

tie %Test, Tie::NetAddr::IP;

$Test{'1.0.0.0/8'} = 1;
$Test{'2.0.0.0/8'} = 2;
$Test{'3.0.0.0/8'} = 3;
$Test{'4.0.0.0/8'} = 4;
$Test{'5.0.0.0/8'} = 5;

is(keys %Test, 5);

for my $k (sort keys %Test) {
    is($Test{$k}, $count);
    ++$count;
}

%Test = ();			# Try CLEAR

$Test{'1.0.0.0/8'} = 6;
$Test{'2.0.0.0/8'} = 7;
$Test{'3.0.0.0/8'} = 8;
$Test{'4.0.0.0/8'} = 9;
$Test{'5.0.0.0/8'} = 10;

for my $k (sort keys %Test) {
    is($Test{$k}, $count);
    ++$count;
}

