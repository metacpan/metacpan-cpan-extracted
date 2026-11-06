
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

use constant HAS_TEST_MEMORYGROWTH => eval { require Test::MemoryGrowth; 1 };
plan skip_all => 'This test requires Test::MemoryGrowth module'
	unless HAS_TEST_MEMORYGROWTH;

################################################################################
# This tests whether Thunderhorse leaks memory
################################################################################

package LeaksApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $router = $self->router;

		$router->add(
			'/' => {
				to => sub ($self, $ctx) {
					return 'hello world';
				}
			}
		);
	}
}

my $app = LeaksApp->new;

Test::MemoryGrowth::no_growth {
	http $app, GET '/';
	http_text_is 'hello world';
}
calls => 1000, 'HTTP operations do not leak';

done_testing;
