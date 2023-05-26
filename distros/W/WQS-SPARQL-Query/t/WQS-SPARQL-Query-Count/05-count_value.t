use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use WQS::SPARQL::Query::Count;

# Test.
my $obj = WQS::SPARQL::Query::Count->new;
my $property = 'P957';
my $isbn = '80-239-7791-1';
my $sparql = $obj->count_value($property, $isbn);
my $right_ret = <<"END";
SELECT (COUNT(?item) as ?count) WHERE {
  ?item wdt:$property '$isbn'
}
END
is($sparql, $right_ret, 'Simple SPARQL count value query.');
