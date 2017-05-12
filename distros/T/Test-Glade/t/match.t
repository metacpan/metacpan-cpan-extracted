#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN { use_ok('Test::Glade') }

# scalars
{
  ok( Test::Glade::match('a', 'a') );
  ok( not Test::Glade::match('a', 'b') );
  ok( Test::Glade::match(17, 18-1) );
}

# array
{
  ok( Test::Glade::match(['a', 'b'], ['a']) );
  ok( not Test::Glade::match(['a', 'b'], ['a', 'c']) );
}

# hash
{
  ok( Test::Glade::match({a => 'b'}, {a => 'b'}) );
  ok( not Test::Glade::match({a => 'b'}, {a => 'c'}) );
}

# put it all together...
{
  my $test = {a => 7, b => ['c'], d => {e => 1}};
  ok( Test::Glade::match($test, {a => 7}) );
  ok( not Test::Glade::match($test, {a => 9}) );
  ok( Test::Glade::match($test, {a => 7, b => ['c']}) );
  ok( not Test::Glade::match($test, {a => 7, b => [12]}) );
  ok( Test::Glade::match($test, {b => ['c'], d => {e => 1}}) );
  ok( not Test::Glade::match($test, {b => ['c'], d => {e => 2}}) );
}
