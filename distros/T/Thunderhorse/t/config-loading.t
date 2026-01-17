use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse::App loads controllers and modules according
# to the "configure" logic
################################################################################

my @build_order;

package LoadingTestController {
	use Mooish::Base -standard;

	extends 'Thunderhorse::Controller';

	sub build ($self)
	{
		$self->router->add(
			'/from-config' => {
				to => 'test',
			}
		);

		push @build_order, __PACKAGE__;
	}

	sub test ($self, $ctx)
	{
		return 'controller: loaded';
	}
}

package LoadingTestModule {
	use Mooish::Base -standard;

	extends 'Thunderhorse::Module';

	sub build ($self)
	{
		weaken $self;

		$self->add_method(
			controller => module_method => sub ($controller) {
				return 'module: ' . ($self->config->{test_option} // 'default');
			}
		);

		push @build_order, __PACKAGE__;
	}
}

package ConfigApp {
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		$self->router->add(
			'/module-test' => {
				to => 'test',
			}
		);

		push @build_order, __PACKAGE__;
	}

	sub test ($self, $ctx)
	{
		return $self->module_method;
	}

	sub sth
	{
		return 'sth';
	}
}

subtest 'should load controllers from config' => sub {
	my $app = ConfigApp->new(
		initial_config => {
			controllers => [
				'^LoadingTestController',
			],
		},
	);

	http $app, GET '/from-config';
	http_status_is 200;
	http_text_is 'controller: loaded';
};

subtest 'should load modules from config' => sub {
	my $app = ConfigApp->new(
		initial_config => {
			modules => {
				'^LoadingTestModule' => {
					test_option => 'configured',
				},
			},
		},
	);

	http $app, GET '/module-test';
	http_status_is 200;
	http_text_is 'module: configured';
};

subtest 'should load both controllers and modules from config' => sub {
	@build_order = ();

	my $app = ConfigApp->new(
		initial_config => {
			controllers => [
				'^LoadingTestController',
			],
			modules => {
				'^LoadingTestModule' => {
					test_option => 'combined',
				},
			},
		},
	);

	is \@build_order, ['LoadingTestModule', 'ConfigApp', 'LoadingTestController'], 'load order ok';

	http $app, GET '/from-config';
	http_status_is 200;
	http_text_is 'controller: loaded';

	http $app, GET '/module-test';
	http_status_is 200;
	http_text_is 'module: combined';
};

subtest 'should load from config file' => sub {
	my $app = ConfigApp->new(
		initial_config => 'config/loading',
	);

	http $app, GET '/from-config';
	http_status_is 200;
	http_text_is 'controller: loaded';

	http $app, GET '/module-test';
	http_status_is 200;
	http_text_is 'module: sth';
};

subtest 'should handle empty config gracefully' => sub {
	my $app = ConfigApp->new;

	http $app, GET '/from-config';
	http_status_is 404;

	http [$app, raise_app_exceptions => false], GET '/module-test';
	http_status_is 500;
};

done_testing;

