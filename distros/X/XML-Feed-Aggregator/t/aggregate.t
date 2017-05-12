use strict;
use warnings;
use Test::More 'no_plan';
use XML::Feed;
use XML::Feed::Aggregator;

# test construction from a mixed list

my $agg = XML::Feed::Aggregator->new({
        feeds => [
            XML::Feed->parse('t_data/slashdot.rss'),
            XML::Feed->parse('t_data/use_perl.rss'),
            XML::Feed->parse('t_data/theregister.atom'),
        ] 
    }
);

isa_ok($agg, 'XML::Feed::Aggregator');

is $agg->entry_count, 0, 'entry count';

$agg->aggregate; # combine

ok $agg->feed_count == 3, 'added feeds';

is $agg->entry_count, 75, 'entry count';

is $agg->error_count, 0,  'no errors';
