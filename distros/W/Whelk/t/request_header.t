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
# This test checks request headers validation built into Whelk.
################################################################################

$t->request(GET '/header')
	->code_is(400)
	->json_cmp({error => re(qr{Header parameters .+->required})});

$t->request(GET '/header', 'X-test1' => 25)
	->code_is(400)
	->json_cmp({error => re(qr{Header parameters .+\[X-Test2\]->required})});

$t->request(GET '/header', 'X-test1' => 25.5, 'X-test2' => 0)
	->code_is(400)
	->json_cmp({error => re(qr{Header parameters .+\[X-Test1\]->integer})});

$t->request(GET '/header', 'X-test1' => 25, 'X-test2' => 0)
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/header', 'X-test1' => 24, 'X-test2' => 1)
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/header', 'X-test1' => 25, 'X-test2' => 1)
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

