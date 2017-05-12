use strict;
use warnings;

use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use FindBin qw( $Bin );
use File::Slurp qw( read_file );

use Test::More tests => 10;

BEGIN { use_ok 'WWW::Discogs' }

my $rt = read_file("$Bin/../requests/search.res");
my $response = HTTP::Response->parse($rt);
$mock_ua->map(
    'http://api.discogs.com/search?page=1&q=Ween&type=all',
    $response
);

my $client = new_ok('WWW::Discogs' => [], '$client');
my $search = $client->search(q => 'Ween');
isa_ok($search, 'WWW::Discogs::Search', '$search');

for ($search->exactresults) {
    if ($_->{title} eq 'Ween') {
        is($_->{type}, 'artist', 'exact type');
        is($_->{title}, 'Ween', 'exact artist');
    }
}

for ($search->searchresults) {
    if ($_->{title} eq 'Ween') {
        is($_->{type}, 'artist', 'search type');
        is($_->{title}, 'Ween', 'search artist');
    }
}

like($search->numresults, qr/^\d+$/, 'numresults');
like($search->pages, qr/^\d+$/, 'pages');
is($search->page, 1, 'page');
