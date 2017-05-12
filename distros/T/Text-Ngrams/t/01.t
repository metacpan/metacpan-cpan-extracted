#!/usr/bin/perl -w

use Test::More tests => 5;
use_ok("Text::Ngrams");
require 't/auxfunctions.pl';

my $ng3 = Text::Ngrams->new;
$ng3->feed_tokens('a');
$ng3->feed_tokens('b');
$ng3->feed_tokens('c');
$ng3->feed_tokens('d');
$ng3->feed_tokens('e');
$ng3->feed_tokens('f');
$ng3->feed_tokens('g');
$ng3->feed_tokens('h');

#putfile('t/01.out', $ng3->to_string( 'orderby' => 'ngram' ));
isn('t/01.out', $ng3->to_string( 'orderby' => 'ngram' ));

is($ng3->{'total_distinct_count'}, 21);
#print $ng3->{'total_distinct_count'}."\n";

is(Text::Ngrams::encode_S("abc\n\t\xF6lado"),
   'abc\\n\\t^vlado');

is(Text::Ngrams::decode_S('abc\\n\\t^vlado'),
   "abc\n\t\xF6lado");
