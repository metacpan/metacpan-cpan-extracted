use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;
use Whelk;
use JSON::PP;

use lib 't/lib';

my $app = Whelk->new(mode => 'deep');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This test checks whether deep-nested (more than one level) resources are
# loaded as they should. In addition, it tests yaml behavior.
################################################################################

$t->request(GET '/deep')
	->code_is(200)
	->yaml_cmp({success => JSON::PP::true, data => 'hello, world!'});

$t->request(GET '/deep/err1')
	->code_is(400)
	->content_type_is('text/plain')
	->content_is('400 - Bad Request');

$t->request(GET '/deep/err2')
	->code_is(500)
	->yaml_cmp({success => JSON::PP::false, error => 'Internal Server Error'});

done_testing;

