use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $client = WebService::Shutterstock::Client->new;
my $customer = WebService::Shutterstock::Customer->new(
	auth_info => { auth_token => 123, username => 'abc' },
	client    => $client
);
isa_ok($customer, 'WebService::Shutterstock::Customer');

can_ok $customer, 'downloads';

{
	my $guard = Test::MockModule->new('REST::Client');
	my $expected_page;
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/abc/images/downloads.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		if(defined $expected_page){
			like $url, qr{page_number=$expected_page}, "has page_number param ($expected_page)";
		} else {
			unlike $url, qr{page_number=}, 'has no page_number param';
		}
		return $self->response(
			response(
				200,
				'{"123123":[{"time":"2012-01-01 00:00:00","image_id":"123","metadata":{"purchase_order":"purchase order"},"license":"premier"}]}'
			)
		);
	});
	my $downloads = $customer->downloads;
	ok exists $downloads->{123123}, 'has subscription 123123';
	$customer->downloads(page_number => $expected_page = 0);
	$customer->downloads(page_number => $expected_page = 1);
}

done_testing;

sub response {
	@_ = [@_] unless ref $_[0] eq 'ARRAY';
	my $code = $_[0]->[0];
	my $data = $_[0]->[1];

	my $method = $_[1]->[0] || 'GET';
	my $uri = $_[1]->[1] || '/';

	my $response = HTTP::Response->new( $code, undef, ['Content-Type' => 'application/json'], $data );
	$response->request(HTTP::Request->new( $method, $uri ));
	return $response;
}
