use Test::More tests => 4;
use WebService::GData::YouTube::Query;


my $ytquery = new WebService::GData::YouTube::Query();


ok(ref($ytquery) eq 'WebService::GData::YouTube::Query','$ytquery is a WebService::GData::YouTube::Query instance.');

ok($ytquery->isa('WebService::GData::Query'),'$ytquery isa WebService::GData::Query.');

ok(!($ytquery->published_min(10)->get('published-min')),'$ytquery can not use published-min parameters and silently fade away...');

ok($ytquery->format(5)->get('format')==5,'$ytquery set the format parameter.');

