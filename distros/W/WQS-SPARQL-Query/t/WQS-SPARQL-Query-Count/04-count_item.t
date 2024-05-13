use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
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

# Test.
$obj = WQS::SPARQL::Query::Count->new;
eval {
	$obj->count_item(123);
};
is($EVAL_ERROR, "Bad property '123'.\n", "Bad property '123'.");
clean();

# Test.
$obj = WQS::SPARQL::Query::Count->new;
eval {
	$obj->count_item('P123', 123);
};
is($EVAL_ERROR, "Bad item '123'.\n", "Bad item '123'.");
clean();
