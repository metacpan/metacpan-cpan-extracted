use strict;

use Test::More;
use Webservice::InterMine;

my $do_live_tests = $ENV{RELEASE_TESTING};

unless ($do_live_tests) {
    plan( skip_all => "Acceptance tests for release testing only" );
} else {
    plan(tests => 3);
    my $url = $ENV{TESTMODEL_URL} || 'http://localhost:8080/intermine-test/service';
    note("Testing against $url");
    my $service = get_service($url, "test-user-token");
    my $list = $service->list("Umlaut holders");
    is($list->size, 2);
    my $all = $list->enrichment(widget => "contractor_enrichment", maxp => 1)->get_all;
    is(~~@$all, 1);
    is($all->[0]{description}, "Ray");
    note explain $all;
}
