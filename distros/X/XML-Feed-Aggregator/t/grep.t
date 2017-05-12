use strict;
use warnings;
use Test::More 'no_plan';
use XML::Feed;
use XML::Feed::Aggregator;

my $agg = XML::Feed::Aggregator->new({
        feeds => [
            XML::Feed->parse('t_data/slashdot.rss'),
        ] 
    }
);

isa_ok($agg, 'XML::Feed::Aggregator');

$agg->aggregate; # combine

is $agg->entry_count, 15, 'entry count';

$agg->grep_entries(sub { $_->title !~ /Book Review/i });

ok $agg->feed_count == 1, 'added feeds';

is $agg->entry_count, 14, 'filtered out one posting';

is $agg->error_count, 0,  'no errors';
