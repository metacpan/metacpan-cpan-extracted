#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib';
use Tie::Nested;
use Hash::Case::Lower;
use Hash::Case::Upper;

use Test::More tests => 13;
use Data::Dumper;

tie my(%a), 'Tie::Nested', nestings =>['Hash::Case::Lower','Hash::Case::Upper'];

like(tied %a, qr/^Tie::Nested\=HASH\(/);

# First level

$a{AaP} = 'b';
is_deeply(\%a, {aap => 'b'}, 'add');

is(delete $a{AAP}, 'b', 'delete');
is_deeply(\%a, {});

# Second level

$a{aap}{Noot} = 42;
is($a{aap}{noot}, 42, 'second level');
$a{GROOT} = 'c';

is_deeply(\%a, {groot => 'c', aap => {NOOT => 42}});

is(delete $a{aAp}{Noot}, 42, 'delete');
is_deeply(\%a, {groot => 'c', aap => {}});

# Third level
$a{AAP}{NOot}{MiEs} = 3;
is_deeply(\%a, {groot => 'c', aap => {NOOT => {MiEs => 3}}});

delete $a{AAP};
delete $a{GROOT};

# Wow

$a{NEW} = {some => {mOrE => 7}};
is($a{nEw}{SoME}{mOrE}, 7, 'multilevel assign');
ok(! exists $a{nEw}{SoME}{MORE}, 'last is case-sensitive');

is_deeply(\%a, {new => {SOME => {mOrE => 7}}});

# now in the tie

tie my(%b), 'Tie::Nested'
  , { NEW => {some => {mOrE => 8}}}
  , nestings =>['Hash::Case::Lower','Hash::Case::Upper'];

is_deeply(\%b, {new => {SOME => {mOrE => 8}}});
