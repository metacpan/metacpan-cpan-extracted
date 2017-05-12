#!/usr/bin/perl -w

use strict;
use Test::Simple tests => 5;
use Yada::Yada::Yada;

local $SIG{__WARN__} = sub { ok(1, "We have a warning") };

if (1 == 1) { ... }

if (1 == 1) {
  ...
}

...

	...


my $string = qq{
  I am 
  ...

  Something
};

ok ($string =~ /\.\.\./, "Didn't interpolate in a string");

