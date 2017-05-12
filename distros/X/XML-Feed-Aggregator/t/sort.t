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

$agg->aggregate; # combine

$agg->sort_by_date;

my ($ent1, $ent2) = $agg->all_entries;

is $ent1->issued->compare($ent2->issued), -1, 'sorted';

is $agg->error_count, 0,  'no errors';
