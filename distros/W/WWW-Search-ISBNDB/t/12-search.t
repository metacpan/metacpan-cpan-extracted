
use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Group;

use Module::Build;

my $build = Module::Build->current;

my $key = $build->args('key');

if (! $key) {
	skip_next_tests 4, 'An API key is required for the extended tests. Please get one at http://isbndb.com/account/dev/keys/';
}

my ($search);

test 'Modules used ok' => sub {
	use_ok( 'WWW::Search' );
	use_ok( 'WWW::Search::ISBNDB' );
};

test 'Object creation' => sub {
	$search = WWW::Search->new('ISBNDB', 'key' => $key);
	ok($search, 'WWW::Search::ISBNDB object created -- good ');
	isa_ok($search, 'WWW::Search::ISBNDB', 'WWW::Search::ISBNDB object ref match -- good ');
};

test 'valid query test' => sub {
	$search->native_query('Born in blood');
	my $result = $search->next_result;
	ok($result, 'got the first result -- good ');
	isa_ok($result, 'WWW::SearchResult', 'WWW::SearchResult object ref match');
	is($result->{'language'}, 'eng', 'language matches -- good');
	is($result->title, 'Born in blood', 'title match');
	is($result->{'titlelong'}, 'Born in blood: the lost secrets of freemasonry', 'long title match');
	is($result->{'isbn'}, '0871316021', 'isbn match -- good')
};

test 'invalid query test' => sub {
	$search->native_query('isbn test ' . time );
	my $result = $search->next_result;
	ok(! $result, 'Found nothing due to an invalid test -- good');
};
