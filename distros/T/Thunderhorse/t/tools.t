use v5.40;
use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests whether Thunderhorse basic app works
################################################################################

package ToolsApp {
	use Mooish::Base -standard;

	use Gears::X::HTTP;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $r = $self->router;

		$r->add(
			'/somewhere/?opt/*arg' => {
				name => 't1',
				defaults => {
					opt => 5,
				},
			}
		);

		$r->add(
			'/redirect' => {
				to => sub ($self, $ctx) {
					$ctx->res->redirect($self->url_for('t1', arg => 'hi'));
				}
			}
		);
	}
}

my $app = ToolsApp->new;
my $c = $app->controller;

subtest 'url_for should work' => sub {
	is $c->url_for('t1', arg => 'hi'), '/somewhere/5/hi', 'default arg ok';
	is $c->url_for('t1', opt => 0, arg => 'ho'), '/somewhere/0/ho', 'passed arg ok';
	is $c->url_for('t1', opt => '1/2', arg => '3/4'), '/somewhere/1%2F2/3/4', 'html-encoding ok';

	ok dies { $c->url_for('t1') }, 'location but no required arg ok';
	ok dies { $c->url_for('bad') }, 'unknown location ok';
};

subtest 'abs_url should work' => sub {
	is $c->abs_url, 'http://localhost:5000', 'abs_url with no arguments ok';
	is $c->abs_url('/test'), 'http://localhost:5000/test', 'abs_url with an argument ok';

	local $app->config->config->{app_url} = 'https://somewhere.world';
	is $c->abs_url, 'https://somewhere.world', 'abs_url data source from app_url ok';
};

subtest 'abs_url_for should work' => sub {
	is $c->abs_url_for('t1', arg => 'hi'), 'http://localhost:5000/somewhere/5/hi', 'abs_url_for works ok';
	is $c->abs_url($c->url_for('t1', arg => 'hi')), $c->abs_url_for('t1', arg => 'hi'),
		'abs_url / url_for integration ok';
	ok dies { $c->abs_url_for('bad') }, 'unknown location ok';
};

subtest 'should redirect' => sub {
	http $app, GET '/redirect';
	http_status_is 302;
	http_header_is 'Location', '/somewhere/5/hi';
};

done_testing;

