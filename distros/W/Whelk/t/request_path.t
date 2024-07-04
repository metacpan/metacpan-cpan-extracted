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
# This test is a placeholder for possible future path validation to be built
# into Whelk. Currently, paths are handled at Kelp level and will return
# text/plain 404 when not matched.
################################################################################

$t->request(GET '/path')
	->code_is(404)
	->content_type_is('text/plain');

$t->request(GET '/path/sth')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/path/25/')
	->code_is(200)
	->json_cmp(JSON::PP::true);

$t->request(GET '/path/2/5')
	->code_is(400)
	->json_cmp({error => re(qr{Path parameters .+\[test2\]->boolean})});

$t->request(GET '/path/str/1')
	->code_is(400)
	->json_cmp({error => re(qr{Path parameters .+\[test1\]->number})});

$t->request(GET '/path/25/0')
	->code_is(200)
	->json_cmp(JSON::PP::false);

$t->request(GET '/path/25/1')
	->code_is(200)
	->json_cmp(JSON::PP::true);

done_testing;

