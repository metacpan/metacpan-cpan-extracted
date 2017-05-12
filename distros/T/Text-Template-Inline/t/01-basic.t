#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;

BEGIN { use_ok('Text::Template::Inline') }

dies_ok(sub { render '1','{2}' }, 'fail without reftype');
lives_ok(sub { render '1','2' }, 'do not fail if no keys replaced');

eval { render '1','{a}' }; my $line = __LINE__;
ok $@ =~ /$0 line $line$/, 'fail from context of caller';

my $data = {
    a => 'aaa',
    a1 => 'a1a',
    b => 'bbb',
    b1 => 'b1b',
    c => 'ccc',
    'b b' => 'invalid',
};

is render($data, '{a} {b}'),       'aaa bbb',       'basic templating';
is render($data, '{e} {b} {f}'),   '{e} bbb {f}',   'missing keys';
is render($data, '{a} {b b} {c} {?}'), 'aaa {b b} ccc {?}', 'ignore invalid';
is render($data, '{{a}} { {b} }'), '{aaa} { bbb }', 'ignore out-of-place braces';
is render($data, '{a1} {b1}'), 'a1a b1b', 'identifiers can include digits';
is eval('render $data => "{a} {b}"'), 'aaa bbb',    'syntactic sugar';

my $nested = { map { $_ => $data } qw/ a b c a1 b1 / };
my $nested2 = { map { $_ => $nested } qw/ a b c a1 b1 / };

is render($nested, '{a.a} {a.b}'), 'aaa bbb', 'basic key paths';
is render($nested2, '{a.a.b} {a.b.a}'), 'bbb aaa', 'nested key paths';
is render($nested2, '{a.c.b1} {c.a1.c}'), 'b1b ccc', 'key paths can include digits';
is render($nested,'{a.z}'), '{a.z}', 'traversal to nonexistent';

eval { render $nested,"{a.c.b}" }; $line = __LINE__;
ok $@ =~ /$0 line $line$/, 'traversal failure with context';

# vi:filetype=perl ts=4 sts=4 et bs=2:
