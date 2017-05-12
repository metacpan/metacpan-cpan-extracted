use strict;
use warnings;
use Test::More 'no_plan';
use XML::Feed;
use XML::Feed::Aggregator;

# test construction from a mixed list

my $agg = XML::Feed::Aggregator->new({
        feeds => [
            XML::Feed->parse('t_data/ironman.rss'),
            XML::Feed->parse('t_data/blogsperl.atom'),
        ] 
    }
);


isa_ok($agg, 'XML::Feed::Aggregator');

$agg->aggregate; # combine

is $agg->entry_count, 56, 'entry count';

$agg->deduplicate;

is $agg->entry_count, 54, 'removed duplicates';

is $agg->error_count, 0, 'no errors';

