#!/usr/bin/perl

# This script tests Text::WikiText, paragraphs syntax.

use strict;
use warnings;

use Test::More;
plan tests => 16;

use_ok('Text::WikiText', ':paragraphs');

can_ok('Text::WikiText', 'new');

my $PARSER = Text::WikiText->new;

isa_ok($PARSER, 'Text::WikiText', 'new works');
can_ok($PARSER, qw(parse parse_paragraph convert));

my $struct;

$struct = $PARSER->parse(<<EOF);
+----+----+
|th1 | th2|
+----+----+
 data|data
 data|data

------

lorem ipsum dolor
rolod muspi merol

{
  i wrote a haiku
  but it is not very good
  so i won't share it

  i wrote one myself
  it is much better than yours
  i should write some more
}

| code 'n' stuff
| and some more.
EOF
#'

my @types = (TABLE(), RULE(), P(), PRE(), CODE());

isa_ok($struct, 'ARRAY', 'parse_paragraph returns array');
is(@$struct, @types, 'number of elements');
for (my $i = 0; $i < @$struct; ++$i) {
	isa_ok($struct->[$i], 'HASH', "element $i");
	is($struct->[$i]{type}, $types[$i], "element $i type");
}
