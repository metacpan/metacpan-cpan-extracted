use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $ss = WebService::Shutterstock->new(api_username => "test", api_key => 123);

can_ok $ss, 'categories';
{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my $self = shift;
		is $_[0], '/categories.json', 'GETs correct URL';
		$ss->client->response(
			response(
				200,
				[ 'Content-Type' => 'application/json' ],
				'[{"category_id":"0","category_name":"Transportation"},{"category_id":"1","category_name":"Animals/Wildlife"}]'
			)
		);
	});
	my $categories = $ss->categories;
	is $categories->[1]->{category_id}, 1, 'returns correct data';
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
