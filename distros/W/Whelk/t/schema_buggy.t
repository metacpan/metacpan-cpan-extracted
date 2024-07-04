use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;
use Whelk;
use JSON::PP;

use lib 't/lib';

my $app = Whelk->new(mode => 'buggy');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This test checks whether buggy Whelk extensions will still result in an API
# that responds with anything (rather than going endless loop).
################################################################################

$t->request(GET '/invalid_planned_error')
	->code_is(505)
	->json_cmp({error => {reason => 'not supported'}});

$t->request(GET '/error_object')
	->code_is(500)
	->content_type_is('text/plain');

done_testing;

