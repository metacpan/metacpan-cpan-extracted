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
		$self->router->add(
			'' => {
				name => 'global_bridge',
				to => 'test_bridge',
			}
		);

		$self->load_controller('Test')
			->load_controller('^TestC2');

		$self->router->add(
			'/base' => {
				to => 'test',
			}
		);
	}

	sub test_bridge ($self, $ctx)
	{
		$ctx->stash->{global_bridge} = true;
		return undef;
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
			'/handles' => {
				to => 'test_handles',
				order => -1,    # order makes sure it is run before bridge
			}
		);

		$self->router->find('global_bridge')->add(
			'/internal' => {
				to => 'test',
			}
		);
	}

	sub test ($self, $ctx)
	{
		die 'no bridge?' unless $ctx->stash->{global_bridge};
		return 'internal: ' . ref $self;
	}

	sub test_handles ($self, $ctx)
	{
		# check if these methods exist (delegated from app)
		# will crash the program if not
		$self->loop;
		$self->config;

		die 'bridge?' if $ctx->stash->{global_bridge};

		return 'ok';
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

subtest 'should contain handles from app' => sub {
	http $app, GET '/handles';
	http_status_is 200;
	http_text_is 'ok';
};

done_testing;

