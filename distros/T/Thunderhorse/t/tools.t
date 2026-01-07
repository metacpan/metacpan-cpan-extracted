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
			'/somewhere/?opt/:arg' => {
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

	ok dies { $c->url_for('t1') }, 'location but no required arg ok';
	ok dies { $c->url_for('bad') }, 'unknown location ok';
};

subtest 'should redirect' => sub {
	http $app, GET '/redirect';
	http_status_is 302;
	http_header_is 'Location', '/somewhere/5/hi';
};

done_testing;

