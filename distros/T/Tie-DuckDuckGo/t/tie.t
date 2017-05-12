use strict;
use warnings;

use Test::More;
use Test::RequiresInternet ('www.duckduckgo.com' => 80);

use_ok('Tie::DuckDuckGo');

my $result;
tie $result, 'Tie::DuckDuckGo', 'perl';
is(ref $result, 'HASH', 'tied scalar returns hash ref');

my @results;
tie @results, 'Tie::DuckDuckGo', 'perl';
is(
    scalar(grep ref($_) eq 'HASH', @results),
    scalar(@results),
    'tied array contains hash refs'
);
ok(exists $results[0], 'EXISTS works on array');

my %search;
tie %search, 'Tie::DuckDuckGo', 'perl';
ok(exists($search{perl}), 'initial search term key defined in hash, and EXISTS works');

done_testing();
