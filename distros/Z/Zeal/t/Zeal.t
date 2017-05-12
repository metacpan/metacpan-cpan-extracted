#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 20;
BEGIN { use_ok('Zeal') };

note 'Working with t/ds/b.docset';
my $ds = Zeal::Docset->new('t/ds/b.docset');
is $ds->name, 'B', 'docset name is B';
is $ds->id, 'b', 'docset id is b';
is $ds->family, 'consonants', 'docset family is consonants';

my @results = $ds->query('buil%');
is @results, 2, 'query(buil%) returns two results';
my $doc = $ds->query('building');
is $doc->name, 'building', 'document name is building';
is $doc->type, 'Word', 'document type is Word';
like $doc->fetch, qr/^Dummy/, 'document HTML starts with "Dummy"';
is $doc->anchor, 'dummy_anchor', 'document anchor is dummy_anchor';

@results = sort {$a->name cmp $b->name} $ds->list;
is @results, 2, 'docset contains two documents';
is $results[0]->name, 'building', 'first result is "building"';

note 'Working with all docsets in t/ds/';
my $zeal = Zeal->new('t/ds/');
eval {
	$zeal->query('family:term');
	fail 'An exception was not thrown when searching for a nonexistent family';
	1
} or like $@, qr/^No docsets/, 'An exception is thrown when searching for a nonexistent family';

my @sets = $zeal->sets;
is @sets, 3, '3 docsets loaded';
@results = $zeal->query('buil%');
is @results, 2, '2 documents begin with "buil"';
@results = $zeal->query('%t%');
is @results, 3, '3 documents contain letter t';
@results = $zeal->query('consonants:%t%');
is @results, 2, '2 documents from the consonants family contain letter t';
@results = $zeal->query('%t%', 'vowels');
is @results, 1, '1 document from the vowels family contain letter t';

note 'Working with t/ds/a.docset via Zeal and ->add';
$zeal = Zeal->new;
$zeal->add('t/ds/a.docset');
@sets = $zeal->sets;
is @sets, 1, '1 docset loaded';
like $sets[0]->get('abou%'), qr/word/, 'HTML for abou% contains the word "word"';

note 'Working with t/ds/a.docset via ZEAL_PATH';
$ENV{ZEAL_PATH} = 't/ds/a.docset';
$zeal = Zeal->new;
is $zeal->query('about')->name, 'about';
