use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;
use Whelk;

my $app = Whelk->new(mode => 'test');
my $t = Kelp::Test->new(app => $app);

$t->request(GET '/openapi.yaml')
	->code_is(200)
	->yaml_cmp(
		superhashof(
			{
				paths => {
					'/todos' => ignore(),
					'/todos/{id}' => ignore(),
				}
			}
		)
	);

done_testing;

