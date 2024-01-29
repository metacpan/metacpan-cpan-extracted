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

	my $search = WWW::Search->new('ValentinskaCZ',
		'search_from_file' => $test_dir->file($html_file)->s,
	);
	$search->maximum_to_retrieve(1);
	my $ret = $search->native_query($query);
	my $first_result_hr = $search->next_result;

	return $first_result_hr;
}

# Test.
my $first_result_hr = test('valentinska_cz-20151030-Capek.html', decode_utf8('Čapek'), {
	version => '20151030',
});
is_deeply(
	$first_result_hr,
	{
		'author' => 'Larbaud, Valery; obálka: J. Čapek',
		'image' => 'http://www.valentinska.cz/image/cache/data/valentinska/book_144061_1-1024x1024.jpg',
		'price' => '450Kč',
		'title' => 'A. O. Barnbooth. Jeho důvěrný deník',
		'url' => 'http://www.valentinska.cz/144061-a-o-barnbooth-jeho-duverny-denik',
	},
	'Parse html page file.',
);
