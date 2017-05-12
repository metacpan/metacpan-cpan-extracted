#!perl

use strict;
use warnings;

use Test::More tests => 5;

use_ok( 'WWW::Yahoo::KeywordExtractor' );

diag( "Testing WWW::Yahoo::KeywordExtractor $WWW::Yahoo::KeywordExtractor::VERSION, Perl $], $^X" );

my ($yke, $keywords);

{
	$yke = WWW::Yahoo::KeywordExtractor->new();
	ok($yke, 'WWW::Yahoo::KeywordExtractor object created');
	isa_ok($yke, 'WWW::Yahoo::KeywordExtractor', 'WWW::Yahoo::KeywordExtractor object ref match');
}

{
	$keywords = $yke->extract('This is a test paragraph.');
	$keywords = $yke->extract('This is a test paragraph. It has lots of funny and cool sentances. Last night we cooked from a really cool book that we got a the store Williams and Sanoma.');
	$keywords = $yke->extract('test test test');
}

{
	eval { $keywords = $yke->extract(''); };
	like($@, qr/No content specified/ , 'empty content test - empty');
	eval { $keywords = $yke->extract(undef); };
	like($@, qr/No content specified/ , 'empty content test - undef');
}
