use Test::More tests => 11;
use WebService::GData::Query;
use WebService::GData::Constants;

my $query = new WebService::GData::Query();


ok(ref($query) eq 'WebService::GData::Query','$query is a WebService::GData::Query instance.');

ok($query->can('v'),'$query has its sub properly installed.');

ok($query->get('v') eq WebService::GData::Constants::GDATA_MINIMUM_VERSION,'$query is set to the proper version.');

ok($query->to_query_string()=~m/alt=json/,'$query reported the proper default alt value.');

eval {
	$query->prettyprint(1);
};
my $error = $@;

ok(ref($error) eq 'WebService::GData::Error','$query complained about wrong parameter values.');

ok($error->code eq 'invalid_parameter_type','$query complained about invalid_parameter values.');

ok($error->content eq 'prettyprint() did not get a proper value.','$query reported the proper function name.');

ok($query->limit(10,0)->get('max-results') == 10,'$query set the proper max results via limit().');

ok($query->get('start-index') == 1,'$query reset the start index to 1 if set to 0.');

WebService::GData::Query::disable([qw(start_index)],'WebService::GData::Query');

ok($query->start_index(10)->get('start-index') == 1,'$query has its start_index method overwritten and did not set it to 10.');

#the order is not kept so just test if overloading does not dump the object...
ok("$query"!~m/WebService::GData::Query/,'$query overloads did call to_query_string().');