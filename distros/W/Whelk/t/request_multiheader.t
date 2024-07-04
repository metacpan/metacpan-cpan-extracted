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
# This test checks array support for header parameter data validation built into
# Whelk.
################################################################################

$t->request(GET '/multiheader')
	->code_is(400)
	->json_cmp({error => re(qr{Header parameters .+\[X-Test\]->required$})});

$t->request(GET '/multiheader', 'X-Test' => 'str')
	->code_is(400)
	->json_cmp({error => re(qr{Header parameters .+->number})});

$t->request(GET '/multiheader', 'X-Test' => 25)
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/multiheader', 'X-Test' => 5, 'X-Test' => 2)
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/multiheader', 'X-Test' => 2, 'X-Test' => 5)
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

