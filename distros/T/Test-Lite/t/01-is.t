#!perl

use Test::Lite;
plan tests => 1;

is 2, 2, { type => 'Int' }, 'Two is Two!';
