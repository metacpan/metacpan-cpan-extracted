use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query::Count;

# Test.
my $obj = WQS::SPARQL::Query::Count->new;
my $property = 'P957';
my $item = 'Q62098524';
my $sparql = $obj->count_item($property, $item);
my $right_ret = <<"END";
SELECT (COUNT(?item) as ?count) WHERE {
  ?item wdt:$property wd:$item
}
END
is($sparql, $right_ret, 'Simple SPARQL count item query.');
