#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib';
use Tie::Nested;
use Hash::Case::Lower;

use Test::More tests => 17;
use Data::Dumper;

tie my(%a), 'Tie::Nested', recurse => 'Hash::Case::Lower';

like(tied %a, qr/^Tie::Nested\=HASH\(/);

# First level

$a{AaP} = 'b';
is_deeply(\%a, {aap => 'b'}, 'add');
is($a{aap}, 'b', 'fetch');
is($a{AAP}, 'b', 'fetch lc');

$a{GrOoT} = 'c';
is_deeply(\%a, {aap => 'b', groot => 'c'}, 'struct');

$a{AAP} = 'x';
is_deeply(\%a, {groot => 'c', aap => 'x'}, 'overwrite');
is(join(' ', sort keys %a), 'aap groot', 'keys');

is(delete $a{AAP}, 'x');
is_deeply(\%a, {groot => 'c'}, 'delete');

# Second level

$a{aap}{Noot} = 42;
is($a{aap}{noot}, 42, 'second level');
is_deeply(\%a, {groot => 'c', aap => {noot => 42}});

$a{AaP}{NOOT} = 43;
is($a{aap}{noot}, 43, 'reassign');
is_deeply(\%a, {groot => 'c', aap => {noot => 43}});

$a{aap}{noot}++;
is($a{aap}{noot}, 44, 'increment');
is_deeply(\%a, {groot => 'c', aap => {noot => 44}});

delete $a{aAp}{nOOt};
is_deeply(\%a, {groot => 'c', aap => {}});

# Many levels

my $dirstruct = { A => { B => 7, C => { D => 8, E => 9 }, F => 10 }
	        , G => 11, H => { I => 12 } };

tie my(%ci), 'Tie::Nested', $dirstruct, recurse => 'Hash::Case::Lower';
is_deeply(\%ci, { a => { b => 7, c => { d => 8, e => 9 }, f => 10 }
	        , g => 11, h => { i => 12 } } );

