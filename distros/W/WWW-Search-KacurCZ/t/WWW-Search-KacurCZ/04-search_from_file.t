use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);
use WWW::Search;

# Test data directory.
my $test_dir = File::Object->new->up->dir('data');

sub test {
	my ($html_file, $query, $options) = @_;

	my $search = WWW::Search->new('KacurCZ',
		'search_from_file' => $test_dir->file($html_file)->s,
	);
	$search->maximum_to_retrieve(1);
	my $ret = $search->native_query($query);
	my $first_result_hr = $search->next_result;

	return $first_result_hr;
}

# Test.
my $first_result_hr = test('kacur_cz-20231212-Capek.html', decode_utf8('Čapek'), {
	version => '20231212',
});
is_deeply(
	$first_result_hr,
	{
		'author' => 'Karel Čapek',
		'cover_url' => 'http://kacur.cz/data/USR_001_OBRAZKY/small_216648.JPG',
		'old_price' => '200 Kč',
		'publisher' => 'Aufbau',
		'price' => undef,
		'title' => 'Der Krieg mit dem Molchen',
		'url' => 'http://kacur.cz/index.asp?menu=1148&record=161171',
	},
	'Parse html page file.',
);
