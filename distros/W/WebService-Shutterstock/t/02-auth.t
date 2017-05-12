use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $ss = WebService::Shutterstock->new(api_username => "test", api_key => 123);

can_ok $ss, 'auth';

ok !eval{ $ss->auth() }, "dies on no params auth call";
like $@, qr{missing 'password'}, 'error message accurate';
{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('POST', sub {
		my $self = shift;
		is $_[0], '/auth/customer.json', 'POSTs to the correct URL';
		like $_[1], qr{username=test}, 'inherits username from api_username';
		like $_[1], qr{password=test-password}, 'password from param';
		$ss->client->{_res} = response(200, ['Content-Type' => 'application/json'], '{"auth_token":"abc123","username":"test123"}');
	});
	$ss->auth(password => 'test-password');
}

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('POST', sub {
		my $self = shift;
		like $_[1], qr{username=someone_else}, 'username from param';
		like $_[1], qr{password=test-password}, 'password from param';
		$ss->client->{_res} = response(200, ['Content-Type' => 'application/json'], '{"auth_token":"abc123","username":"test123"}');
	});
	my $customer = $ss->auth(username => 'someone_else', password => 'test-password');
	is $customer->username, 'test123', 'successful auth - username';
	is $customer->auth_token, 'abc123', 'successful auth - auth_token';
}

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('POST', sub {
		$ss->client->{_res} = response(401);
	});
	eval { $ss->auth(username => 'someone_else', password => 'test-password') };
	like $@, qr{invalid api}, 'invalid api authorization';
}

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('POST', sub {
		$ss->client->{_res} = response([403],['POST','/auth/customer.json']);
	});
	eval { $ss->auth(username => 'someone_else', password => 'test-password') };
	like $@, qr{403 Forbidden}, 'invalid username/password';
}

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('POST', sub {
		$ss->client->{_res} = response([200, undef, 'garbage'],['POST','/auth/customer.json']);
	});
	eval { $ss->auth(username => 'someone_else', password => 'test-password') };
	like $@, qr{garbage}, 'has error';
}

done_testing;

sub response {
	@_ = [@_] unless ref $_[0] eq 'ARRAY';
	my $code = $_[0]->[0];
	my $headers = $_[0]->[1];
	my $data = $_[0]->[2];
	my $method = $_[1]->[0] || 'GET';
	my $uri = $_[1]->[1] || '/';
	my $response = HTTP::Response->new( $code, undef, $headers, $data );
	$response->request(HTTP::Request->new( $method, $uri ));
	return $response;
}
