#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

use Types::Algebraic;

data Maybe = Just :v | Nothing;

isnt(Just(5), Nothing, "Just 5 is not Nothing");
isnt(Just(5), Just(7), "Just 5 is not Just 7");
is(Just(5), Just(5), "Just 5 is Just 5");

is(Nothing, Nothing, "Nothing is not Nothing");
isnt(Nothing, Just(7), "Nothing is not Just 7");
isnt(Nothing, Just(5), "Nothing is not Just 5");

isnt(Just("hey"), Just("goodbye"), 'Just "hey" is not Jusy "goodbye"');
is(Just("goodbye"), Just("goodbye"), 'Just "goodbye" is Just "goodbye"');
