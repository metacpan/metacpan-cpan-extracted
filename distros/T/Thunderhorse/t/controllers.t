use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse controllers work
################################################################################

package ControllersApp {
	use v5.40;
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->load_controller('Test')
			->load_controller('^TestC2');

		$self->router->add(
			'/base' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		return 'base: ' . ref $self;
	}
};

package ControllersApp::Controller::Test {
	use v5.40;
	use Mooish::Base -standard;

	extends 'Thunderhorse::Controller';

	sub build ($self)
	{
		$self->router->add(
			'/internal' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		return 'internal: ' . ref $self;
	}
}

package TestC2 {
	use v5.40;
	use Mooish::Base -standard;

	extends 'Thunderhorse::Controller';

	sub build ($self)
	{
		$self->router->add(
			'/external' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		return 'external: ' . ref $self;
	}
}

my $app = ControllersApp->new;

subtest 'should route to a valid location' => sub {
	http $app, GET '/base';
	http_status_is 200;
	http_text_is 'base: Thunderhorse::AppController';

	http $app, GET '/internal';
	http_status_is 200;
	http_text_is 'internal: ControllersApp::Controller::Test';

	http $app, GET '/external';
	http_status_is 200;
	http_text_is 'external: TestC2';
};

done_testing;

