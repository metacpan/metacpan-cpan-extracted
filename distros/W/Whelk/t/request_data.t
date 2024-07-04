use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;
use Whelk;
use JSON::PP;

use lib 't/lib';

my $app = Whelk->new(mode => 'requests');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This test checks request data validation built into Whelk.
################################################################################

$t->request(
	POST '/body',
	)
	->code_is(400)
	->json_cmp({error => 'Unsupported Content-Type'});

$t->request(
	POST '/body',
	Content_Type => 'application/json',
	)
	->code_is(400)
	->json_cmp({error => 'Content error at: object'});

$t->request(
	POST '/body',
	Content_Type => 'application/json',
	Content => '[]',
	)
	->code_is(400)
	->json_cmp({error => 'Content error at: object'});

$t->request(
	POST '/body',
	Content_Type => 'application/json',
	Content => '{}',
	)
	->code_is(400)
	->json_cmp({error => 'Content error at: object[test]->required'});

$t->request(
	POST '/body',
	Content_Type => 'application/json',
	Content => '{"test": 25.5}',
	)
	->code_is(400)
	->json_cmp({error => 'Content error at: object[test]->integer'});

$t->request(
	POST '/body',
	Content_Type => 'application/json',
	Content => '{"test": 13}',
	)
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(
	POST '/body',
	Content_Type => 'application/json',
	Content => '{"test": 25}',
	)
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

