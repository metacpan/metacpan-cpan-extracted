use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;
use Whelk;
use JSON::PP;

use lib 't/lib';

my $app = Whelk->new(mode => 'requests');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This test checks query parameter data validation built into Whelk.
################################################################################

$t->request(GET '/query')
	->code_is(400)
	->json_cmp({error => re(qr{Query parameters .+->required})});

$t->request(GET '/query?test1=25')
	->code_is(400)
	->json_cmp({error => re(qr{Query parameters .+\[test2\]->required})});

$t->request(GET '/query?test1=25.5&test2=')
	->code_is(400)
	->json_cmp({error => re(qr{Query parameters .+\[test1\]->integer})});

$t->request(GET '/query?test1=25&test2=')
	->code_is(200)
	->header_is(X_Default => 'a default')
	->json_cmp(JSON::PP::false);

$t->request(GET '/query?test1=25&test2=&def=test')
	->code_is(200)
	->header_is(X_Default => 'test')
	->json_cmp(JSON::PP::false);

$t->request(GET '/query?test1=24&test2=1')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/query?test1=25&test2=1')
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

