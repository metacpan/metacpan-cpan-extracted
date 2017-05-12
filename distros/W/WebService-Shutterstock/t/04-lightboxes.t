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

can_ok $customer, 'lightboxes';

{
	my $guard = Test::MockModule->new('REST::Client');
	my $expected_get_url = qr'/customers/abc/lightboxes/extended.json\?';
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/abc/lightboxes/extended.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		return $self->{_res} = response(200, '[{"lightbox_id":1,"lightbox_name":"test","images":[{"image_id":1,"sizes":{"huge":{"height":100,"width":100}}}]},{"lightbox_id":2, "lightbox_name":"test 2","images":[{"image_id":2}]}]');
	});
	my $lightboxes = $customer->lightboxes(1);
	is @$lightboxes, 2, 'has two lightboxes';
	is $lightboxes->[1]->id, 2, 'correct data - id';
	is $lightboxes->[1]->name, 'test 2', 'correct data - name';

	$guard->mock('PUT' => sub {
		my($self, $url) = @_;
		like $url, qr{/lightboxes/1/images/123.json\?}, 'correct URL (PUT)';
		like $url, qr{username=abc}, 'has username (PUT)';
		like $url, qr{auth_token=123}, 'has username (PUT)';
	});
	$lightboxes->[0]->add_image(123);
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/lightboxes/1/extended.json\?', 'correct URL';
		like $url, qr{auth_token=123}, 'includes auth_token';
		return $self->{_res} = response(200, '{"lightbox_id":1,"lightbox_name":"test","images":[{"image_id":1,"sizes":{"huge":{"height":100,"width":100}}}]}');
	});
	is $lightboxes->[0]->{_images}, undef, 'cleared images';
	isa_ok $lightboxes->[0]->_images, 'ARRAY';

	$guard->mock('DELETE' => sub {
		my($self, $url) = @_;
		like $url, qr{/lightboxes/1/images/123.json\?}, 'correct URL (DELETE)';
		like $url, qr{username=abc}, 'has username (DELETE)';
		like $url, qr{auth_token=123}, 'has username (DELETE)';
	});
	$lightboxes->[0]->delete_image(123);
	is $lightboxes->[0]->{_images}, undef, 'cleared images';
	isa_ok $lightboxes->[0]->_images, 'ARRAY';
}

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/customers/abc/lightboxes.json\?', 'correct URL (not extended)';
		return $self->response(response(200, '[{"lightbox_id":1,"lightbox_name":"test","images":[{"image_id":1,"sizes":{"huge":{"height":100,"width":100}}}]},{"lightbox_id":2, "lightbox_name":"test 2","images":[{"image_id":2}]}]'));
	});
	$customer->lightboxes;
}

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my($self, $url) = @_;
		like $url, qr'/lightboxes/\d+/extended.json', 'correct URL';
		my($id) = $url =~ qr'/lightboxes/(\d+)';
		if($id == 1){
			return $self->response(response(200, '{"lightbox_id":1,"lightbox_name":"test","images":[{"image_id":1,"sizes":{"huge":{"height":100,"width":100}}}]}'));
		} else {
			return $self->response( response(404, '') );
		}
	});
	my $lightbox = $customer->lightbox(1);
	isa_ok $lightbox, 'WebService::Shutterstock::Lightbox';
	my $other = $customer->lightbox(2);
	is $other, undef, "lightbox 2 does not exist";
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
