# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 26;
use Tie::Array::BoundedIndex;

my $RANGE_EXCEP = qr/out of range/;
my @array;
tie @array, 'Tie::Array::BoundedIndex', upper => 5;

my $t_e_installed;
BEGIN {
  if (eval "require Test::Exception")
  {
    Test::Exception->import;
    $t_e_installed = 1;
  }
  else
  {
    eval 'sub lives_ok (&$) { $_[0]->() }
          sub throws_ok (&$$) { eval { $_[0]->() } }';
    $t_e_installed = 0;
  }
}

SKIP: {
  lives_ok { $array[0] = 42 } "Store works";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

is($array[0], 42, "Fetch works");

SKIP: {
  throws_ok { $array[6] = "dog" } $RANGE_EXCEP,
            "Bounds exception";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

is_deeply(\@array, [ 42 ], "Array contents correct");

SKIP: {
  lives_ok { push @array, 17 } "Push works";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

is($array[1], 17, "Second array element correct");

SKIP: {
  lives_ok { push @array, 2, 3 } "Push multiple elements works";

  lives_ok { $array[-1] = 4 } "Negative index works";
  skip "Test::Exception not installed", 2 unless $t_e_installed;
}

is_deeply(\@array, [ 42, 17, 2, 4 ], "Array contents correct");

SKIP: {
lives_ok { splice(@array, 4, 0, qw(apple banana)) } "Splice works";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

is_deeply(\@array, [ 42, 17, 2, 4, 'apple', 'banana' ],
	  "Array contents correct");

SKIP: {
  throws_ok { push @array, "excessive" } $RANGE_EXCEP,
            "Push bounds exception";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

is(scalar @array, 6, "Size of array correct");

SKIP: {
  throws_ok { splice(@array, 6, 1, "still excessive") } $RANGE_EXCEP,
            "Splice bounds exception";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

tie @array, "Tie::Array::BoundedIndex", lower => 3, upper => 6;

SKIP: {
  throws_ok { $array[1] = "too small" } $RANGE_EXCEP,
            "Lower bound check failure";

  lives_ok { @array[3..6] = 3..6 } "Slice assignment works";

  throws_ok { push @array, "too big" } $RANGE_EXCEP,
            "Push bounds exception";

  throws_ok { unshift @array, "too much" } $RANGE_EXCEP,
            "Unshift bounds exception";
  skip "Test::Exception not installed", 4 unless $t_e_installed;
}

is(shift(@array), 3, "shift works");

is_deeply([ @array[3..5] ], [ 4..6 ], "Array contents correct");

is_deeply([ splice(@array, 3, 3) ], [ 4..6 ], "Splice result correct");

SKIP: {
  throws_ok { splice(@array, 3, 1, 3..7) } $RANGE_EXCEP,
            "Splice bounds exception";
  skip "Test::Exception not installed", 1 unless $t_e_installed;
}

is(0, scalar(@array), "Array emptied");

is(undef, shift(@array), "Shift on empty array correct");

tie @array, "Tie::Array::BoundedIndex", upper => 0;

SKIP: {
  lives_ok { $array[0] = 42 } "Zero bound array store okay";

  throws_ok { $array[1] = 17 } $RANGE_EXCEP, "Zero bounds array exception";
  skip "Test::Exception not installed", 2 unless $t_e_installed;
}
