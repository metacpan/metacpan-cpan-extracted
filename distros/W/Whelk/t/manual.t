use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use Test::Deep;
use HTTP::Request::Common;
use Whelk;

use lib 't/lib';

my $app = Whelk->new(mode => 'manual');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This tests whether complex examples from the manual are correct. Needs to be
# kept up to date when manual changes.
################################################################################

$t->request(GET '/pangrams')
	->code_is(200)
	->json_cmp(
		superbagof(
			{
				language => 'English',
				pangram => 'a quick brown fox jumped over a lazy dog',
			}
		)
	);

$t->request(POST '/multiply/3', Content_Type => 'application/json', Content => '{}')
	->code_is(200)
	->json_cmp({number => 3});

$t->request(POST '/multiply/3', Content_Type => 'application/json', Content => '{}', 'X-Number' => 5)
	->code_is(200)
	->json_cmp({number => 15});

$t->request(POST '/multiply/3?number=5', Content_Type => 'application/json', Content => '{}')
	->code_is(200)
	->json_cmp({number => 15});

$t->cookies->set_cookie(0, number => 5);
$t->request(POST '/multiply/7', Content_Type => 'application/json', Content => '{}')
	->code_is(200)
	->json_cmp({number => 35});

$t->request(POST '/multiply/3', Content_Type => 'text/yaml', Content => 'number: 7')
	->code_is(200)
	->json_cmp({number => 105});

done_testing;

