use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;

BEGIN {
	my $has_moo = eval { require Moo; 1 };
	plan skip_all => 'These tests require Moo'
		unless $has_moo;
}

use lib 't/lib';
use KelpMoo;

my $app = KelpMoo->new(mode => 'kelpmoo');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This tests a couple things:
# - whether Whelk can be used as Kelp module
# - whether Moo can be used instead of Kelp::Base and consumes the role
# - whether resources with +Full::Namespace work
################################################################################

$t->request(GET '/')
	->code_is(200)
	->json_cmp(['moo']);

$t->request(GET '/openapi.json')
	->code_is(200)
	->content_type_is('application/json');

done_testing;

