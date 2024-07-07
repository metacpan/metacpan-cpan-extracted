use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;

use lib 't/lib';
use KelpCustom;

my $app = KelpCustom->new(mode => 'kelpcustom');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This tests whether Whelk works with custom base controller for Kelp
################################################################################

$t->request(GET '/test')
	->code_is(200)
	->json_cmp([qw(three two one)]);

$t->request(GET '/openapi.json')
	->code_is(200)
	->content_type_is('application/json');

done_testing;

