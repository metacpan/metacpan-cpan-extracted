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
# This test checks cookie parameter data validation built into Whelk.
################################################################################

$t->request(GET '/cookie')
	->code_is(400)
	->json_cmp({error => re(qr{Cookie parameters .+->required})});

$t->cookies->set_cookie(0, test1 => 25);
$t->request(GET '/cookie')
	->code_is(400)
	->json_cmp({error => re(qr{Cookie parameters .+\[test2\]->required})});

$t->cookies->set_cookie(0, test1 => 25.5);
$t->cookies->set_cookie(0, test2 => '');
$t->request(GET '/cookie')
	->code_is(400)
	->json_cmp({error => re(qr{Cookie parameters .+\[test1\]->integer})});

$t->cookies->set_cookie(0, test1 => 25);
$t->cookies->set_cookie(0, test2 => '');
$t->request(GET '/cookie')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->cookies->set_cookie(0, test1 => 24);
$t->cookies->set_cookie(0, test2 => 1);
$t->request(GET '/cookie')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->cookies->set_cookie(0, test1 => 25);
$t->cookies->set_cookie(0, test2 => 1);
$t->request(GET '/cookie')
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

