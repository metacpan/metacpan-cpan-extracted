use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $ss = WebService::Shutterstock->new(api_username => "test", api_key => 123);

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('POST', sub {
		my($self, $uri) = @_;
		$ss->client->{_res} = response(
				[ 400, [ 'Content-Type' => 'text/plain' ], 'Dude!' ],
				[ 'POST', $uri ]
		);
	});
	eval {
		$ss->auth(password => 'test-password');
		ok(0, 'exception thrown correctly');
		1;
	} or do {
		my $e = $@;
		isa_ok($e, 'WebService::Shutterstock::Exception');
		unlike("$e", qr/WebService::Shutterstock/, "stringifies to error");
		can_ok($e, 'response','code','method','uri' );
		is($e->code, '400', 'exception has correct status code');
		is $e->method, 'POST', 'correct HTTP method';
		is $e->uri, '/auth/customer.json', 'correct URI';
		like $e, qr{400 Bad Request: Dude! at}, 'error message OK';
	}
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
