#!/usr/bin/perl

# This script tests Text::WikiText, environment syntax.

use strict;
use warnings;

use Test::More;
plan tests => 14;

use_ok('Text::WikiText', ':environment');

can_ok('Text::WikiText', 'new');

my $PARSER = Text::WikiText->new;

isa_ok($PARSER, 'Text::WikiText', 'new works');
can_ok($PARSER, qw(parse parse_paragraph convert));

my $struct;

$struct = $PARSER->parse(<<EOF);
> Lots of folks confuse bad management with destiny.

* me,
* myself,
* and i

1. one
2. two
3. three

:a: bc
:z: yx
:1: 23
EOF

my @types = (QUOTE(), LISTING(), ENUMERATION(), DESCRIPTION());

isa_ok($struct, 'ARRAY', 'parse_paragraph returns array');
is(@$struct, @types, 'number of elements');
for (my $i = 0; $i < @$struct; ++$i) {
	isa_ok($struct->[$i], 'HASH', "element $i");
	is($struct->[$i]{type}, $types[$i], "element $i type");
}
