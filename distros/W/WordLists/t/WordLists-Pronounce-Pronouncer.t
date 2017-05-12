#!perl -w
use strict;
use utf8;
use Test::More;
use WordLists::Pronounce::Pronouncer;
use WordLists::Parse::Simple;
use WordLists::WordList;
use WordLists::Lookup;
my $wl = WordLists::WordList->new({from_file=>'t/test-prons.idx', encoding=>'UTF-8', parser=>WordLists::Parse::Simple->new({line_sep=>"\x0d\x0a"})});

my $lookup = WordLists::Lookup->new({dicts=>[$wl]});

ok(my $pronouncer = WordLists::Pronounce::Pronouncer->new({lookup=>$lookup}), 'can create a pronouncer object');
is($pronouncer->pronounce_phrase('tests', {field=>'ukpron'}), 'tests', 'can pronounce a word');
is($pronouncer->pronounce_phrase('testing tests', {field=>'ukpron'}), 'ˈtest.ɪŋ tests', 'can pronounce a phrase');

done_testing();
