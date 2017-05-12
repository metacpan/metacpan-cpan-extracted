use strict;
use warnings;
use Test::More 'no_plan';
use XML::Feed;
use XML::Feed::Aggregator;

my $agg = XML::Feed::Aggregator->new({
        feeds => [
            XML::Feed->parse('t_data/slashdot.rss'),
            XML::Feed->parse('t_data/ironman.rss'),
        ]
    }
);

isa_ok($agg, 'XML::Feed::Aggregator');

$agg->aggregate;

is $agg->error_count, 0,  'no errors';

my $feed = $agg->to_feed('RSS');
isa_ok $feed, 'XML::Feed';
