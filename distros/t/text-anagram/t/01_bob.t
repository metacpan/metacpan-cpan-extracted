#! /usr/bin/perl
use Test::More tests => 2;
use Text::Anagram;

my @r;
Text::Anagram::anagram {push @r,$_} "box";
ok( (@r == 6)
, "found all occurences of box");

@r=();
Text::Anagram::anagram {push @r,$_} "bob";
ok( (@r == 3)
, "bob is not bob (2b or not 2b)");
