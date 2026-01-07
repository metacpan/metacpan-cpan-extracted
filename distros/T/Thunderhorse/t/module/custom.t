use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse modules work (based on a custom module)
################################################################################

package TestModule {
	use Mooish::Base -standard;

	extends 'Thunderhorse::Module';

	sub build ($self)
	{
		$self->register(
			controller => custom_method => sub ($controller, $text) {
				return "custom: $text";
			}
		);
	}
}

package ModuleApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_module('^TestModule');

		$self->router->add(
			'/test' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		return $self->custom_method('works');
	}
}

my $app = ModuleApp->new;

subtest 'should have access to module method' => sub {
	http $app, GET '/test';
	http_status_is 200;
	http_text_is 'custom: works';
};

done_testing;

