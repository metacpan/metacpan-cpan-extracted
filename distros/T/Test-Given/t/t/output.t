use Test::Given;
use strict;
use warnings;

our ($hash, $array);

describe 'Output in package main::' => sub {
  Given hash => sub { {a => 1, b => 2} };
  Given array => sub { [1, 2, 3] };
  Given '&sub' => sub { sub { 'a sub' } };
  Then sub { $hash->{a} == $array->[1] };
  Then sub { "$hash->{b}" eq "$array->[2]" };
  Then sub { &sub() eq (keys(%$hash))[0] };
};

package mypackage;
use Test::Given;
use strict;
use warnings;

our ($a, $b, $c);

describe 'Output within package' => sub {
  Given a => sub { 1 };
  Given b => sub { 2 };
  Given c => sub { undef };
  Then sub { $a / ( $b + 2 * $a ) == $a / ( $b - 2 * $a ) };
  Then sub { die('hard') == die('vengeance') };
  Then sub { $b - 2 * $a };
  Then sub { return $a == $c };
};
