#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
my $accumulator;

use Tie::STDOUT
    print    => sub { $accumulator = ''; $accumulator .= uc($_) foreach(@_) },
    printf   => sub { $accumulator = ''; my $fmt = shift(); $accumulator .= uc(sprintf($fmt, @_)) },
    syswrite => sub { $accumulator = ''; $accumulator = substr(uc($_[0]), $_[2], $_[1]) };

print qw(foo bar baz);
is($accumulator, 'FOOBARBAZ', "user-defined 'print' works");

printf "%s %d", "foo", 20;
is($accumulator, 'FOO 20', "user-defined 'printf' works");

syswrite(STDOUT, "gibberish", 5, 2);
is($accumulator, 'BBERI', "user-defined 'syswrite' works");

done_testing();
