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
# This test checks array support for query parameter data validation built into
# Whelk.
################################################################################

$t->request(GET '/multiquery')
	->code_is(400)
	->json_cmp({error => re(qr{Query parameters .+\[test\]->required$})});

$t->request(GET '/multiquery?test=str')
	->code_is(400)
	->json_cmp({error => re(qr{Query parameters .+->number})});

$t->request(GET '/multiquery?test=25')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/multiquery?test=5&test=2')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/multiquery?test=2&test=5')
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

