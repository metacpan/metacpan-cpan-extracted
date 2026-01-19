use Test2::V1 -ipP;
use Test2::Thunderhorse;
use HTTP::Request::Common;

################################################################################
# This tests Thunderhorse edge cases
################################################################################

package EdgeApp {
	use v5.40;
	use Mooish::Base -standard;

	extends 'Thunderhorse::App';

	sub build ($self)
	{
		my $r = $self->router;

		# it is possible to have multiple locations, and the first one which
		# renders stops the execution chain
		$r->add('/multi' => {to => sub { return undef }});
		$r->add('/multi');
		$r->add('/multi' => {to => sub { return 'this gets rendered' }});
		$r->add('/multi' => {to => sub { return 'this does not rendered' }});

		# normally routes are returned in the order of declaration and nesting,
		# however it is possible to specify order explicitly (lower gets
		# executed faster). Routes which are not ordered should stay in the
		# order of declaration
		$r->add('/order' => {to => sub { shift->stash_and_return(@_, 'first declared') }});
		$r->add('/order' => {to => sub { shift->stash_and_return(@_, 'positive order') }, order => 1});
		$r->add('/order' => {to => sub { shift->stash_and_return(@_, 'after all') }, order => 1});
		my $b = $r->add('/order' => {to => sub { shift->stash_and_return(@_, 'bridge') }});
		$b->add('' => {to => sub { shift->stash_and_return(@_, 'first bridged') }});
		$b->add('' => {to => sub { shift->stash_and_return(@_, 'second bridged') }, order => -1});
		$b->add('' => {to => sub { shift->stash_and_return(@_, 'third bridged') }});
		$r->add('/order' => {to => sub { shift->stash_and_return(@_, 'before bridge') }, order => -1});
		$r->add('/order' => {to => sub { shift->stash_and_return(@_, 'last declared') }});
		$r->add('/order' => {to => 'print_stash', order => 9});

		# routes with normally catch all actions, but it is possible
		# to specify a single action in router too
		$r->add('/any_action' => {to => 'print_method'});
		$r->add('/only_post' => {to => 'print_method', action => 'http.post'});

		$r->add('/future' => {to => 'return_future'});
	}

	sub stash_and_return ($self, $ctx, $msg)
	{
		push $ctx->stash->{order}->@*, $msg;
		return undef;
	}

	sub print_stash ($self, $ctx)
	{
		return join ' -> ', $ctx->stash->{order}->@*;
	}

	sub print_method ($self, $ctx)
	{
		return $ctx->req->method;
	}

	sub return_future ($self, $ctx)
	{
		return $ctx->res->text('return text without await');
	}
};

my $app = EdgeApp->new;

subtest 'should handle multiple locations for the same route' => sub {
	http $app, GET '/multi';
	http_status_is 200;
	http_text_is 'this gets rendered';
};

subtest 'should respect route ordering' => sub {
	my @order = (
		'before bridge',
		'first declared',
		'bridge',
		'second bridged',
		'first bridged',
		'third bridged',
		'last declared',
		'positive order',
		'after all',
	);

	http $app, GET '/order';
	http_status_is 200;
	http_text_is join ' -> ', @order;
};

subtest 'should handle action-specific routing' => sub {
	http $app, GET '/any_action';
	http_status_is 200;
	http_text_is 'GET';

	http $app, POST '/any_action';
	http_status_is 200;
	http_text_is 'POST';

	http $app, GET '/only_post';
	http_status_is 404;

	http $app, POST '/only_post';
	http_status_is 200;
	http_text_is 'POST';
};

subtest 'should not allow multiple routes with the same name' => sub {
	$app->router->add('/_test1' => {name => '_test'});
	my $ex = dies {
		$app->router->add('/_test2' => {name => '_test'});
	};

	isa_ok $ex, 'Gears::X::Thunderhorse';
	like $ex, qr{must be unique}, 'exception ok';
};

subtest 'returning future from handler should work' => sub {
	http $app, GET '/future';
	http_status_is 200;
	http_header_is 'content-type', 'text/plain; charset=utf-8';
	http_text_is 'return text without await';
};

done_testing;

