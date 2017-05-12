# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test;
BEGIN { plan tests => 516 };
use Tie::GHash;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

{
  tie my %hash, 'Tie::GHash';
  ok(1);
}

ok(1);

tie my %h, 'Tie::GHash';

$h{"foo"} = "red";
ok(1);
ok(defined $h{"foo"});
ok($h{"foo"}, "red");

$h{"foo"} = "blue";
ok($h{"foo"}, "blue");

$h{"foo"} = "red-blue";
ok($h{"foo"}, "red-blue");

ok(not defined $h{"bar"});
my $colour = "green";
$h{"bar"} = $colour;
ok($h{"bar"}, "green");
$colour = "yellow";
ok($h{"bar"}, "green");

foreach my $i (1..100) {
  $h{"quux"} = $i;
  ok($h{"quux"}, $i);
}

foreach my $i (1..100) {
  $h{"quux"} = $i;
  ok($h{"quux"}, $i);
  delete $h{"quux"};
  ok(not defined $h{"quux"});
}

foreach my $i (1..100) {
  $h{$i} = $i * 2;
  ok($h{$i}, $i * 2);
}

foreach my $i (1..100) {
  my $j = $i + 1;
  $h{"foo: $i"} = $j;
  ok($h{"foo: $i"}, $j);
}

tie my %squares, 'Tie::GHash';
foreach my $i (1..100) {
  $squares{$i} = $i * 2;
}

my @foo = keys %squares;
ok(1);

my($sum, $geomsum);
foreach my $k (keys %squares) {
print "fooo!\n";
  $sum += $k;
  $geomsum += $squares{$k};
}
ok($sum, 5050);
ok($geomsum, 10100);

($sum, $geomsum) = (0, 0);
while (my($key,$val) = each %squares) {
  $sum += $key;
  $geomsum += $val;
}
ok($sum, 5050);
ok($geomsum, 10100);




