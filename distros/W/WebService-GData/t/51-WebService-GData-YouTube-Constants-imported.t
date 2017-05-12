use Test::More tests => 5;
use WebService::GData::YouTube::Constants qw(:all);


ok(MOBILE_H263 ==1,'MOBILE_H263 is properly imported');

ok(PROJECTION eq 'api','PROJECTION is properly imported');

ok(TODAY eq 'today','TODAY is properly imported');

ok(NONE eq 'none','NONE is properly imported');

ok(RELEVANCE eq 'relevance','RELEVANCE is properly imported');