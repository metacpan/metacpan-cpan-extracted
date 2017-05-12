#!/usr/bin/perl

# This script tests Text::WikiText, inline syntax.

use strict;
use warnings;

use Test::More;
plan tests => 32;

use_ok('Text::WikiText', ':inline');

can_ok('Text::WikiText', 'new');

my $PARSER = Text::WikiText->new;

isa_ok($PARSER, 'Text::WikiText', 'new works');
can_ok($PARSER, qw(parse parse_paragraph convert));

my $struct;

$struct = $PARSER->parse_paragraph('/emph/ *strong* _underline_ -strike- {typewriter} [link] {{verbatim}}');

my @types = (
	EMPHASIS(), TEXT(), STRONG(), TEXT(),
	UNDERLINE(), TEXT(), STRIKE(), TEXT(),
	TYPEWRITER(), TEXT(), LINK(), TEXT(),
	VERBATIM(),
);

isa_ok($struct, 'ARRAY', 'parse_paragraph returns array');
is(@$struct, @types, 'number of elements');
for (my $i = 0; $i < @$struct; ++$i) {
	isa_ok($struct->[$i], 'HASH', "element $i");
	is($struct->[$i]{type}, $types[$i], "element $i type");
}
