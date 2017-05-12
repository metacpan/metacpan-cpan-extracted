#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;

use autobox::dump;

my @a = qw/a b c d 0/;
my $ref = \@a;
my @lol = map { [ 1 .. 5 ] } 1 .. 5;

is_deeply eval @a->perl, [@a];

is_deeply eval [@a]->perl, [@a];

is_deeply eval $ref->perl, $ref;

is_deeply eval @lol->perl, \@lol;

#test passing of options
is @a->perl([Indent => 0], [Varname => 'a'], qw/Useqq/), 
    qq(\$a1 = ["a","b","c","d",0];);

#no options still works normally
is [0]->perl, "[\n  0\n]\n";

#test setting defaults

can_ok "autobox::dump", qw/options/;

autobox::dump->options([Indent => 0], [Varname => 'a'], qw/Useqq/);

is @a->perl, qq(\$a1 = ["a","b","c","d",0];);
