#!/usr/bin/perl

# This script tests Text::WikiText, generic syntax.

use strict;
use warnings;

use Test::More;
plan tests => 10;

use_ok('Text::WikiText', ':generic');

can_ok('Text::WikiText', 'new');

my $PARSER = Text::WikiText->new;

isa_ok($PARSER, 'Text::WikiText', 'new works');
can_ok($PARSER, qw(parse parse_paragraph convert));

my $struct;

$struct = $PARSER->parse(<<EOF);
(comment)
yadda yadda
(end comment)

{{ verbatim }}
EOF

my @types = (COMMENT(), VERBATIM());

isa_ok($struct, 'ARRAY', 'parse_paragraph returns array');
is(@$struct, @types, 'number of elements');
for (my $i = 0; $i < @$struct; ++$i) {
	isa_ok($struct->[$i], 'HASH', "element $i");
	is($struct->[$i]{type}, $types[$i], "element $i type");
}
