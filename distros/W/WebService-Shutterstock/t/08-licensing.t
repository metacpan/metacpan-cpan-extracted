use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;
use WebService::Shutterstock::Subscription;
use JSON qw(encode_json);

my $client = WebService::Shutterstock::Client->new;
my $customer = WebService::Shutterstock::Customer->new(
	auth_info     => { auth_token => 123, username => 'abc' },
	client        => $client,
	subscriptions => [
		WebService::Shutterstock::Subscription->new(
			site            => 'photo_subscription',
			auth_info            => { auth_token => 124, username => 'abc' },
			client               => $client,
			subscription_id      => 1,
			license              => 'premier',
			unix_expiration_time => 0
		),
		WebService::Shutterstock::Subscription->new(
			site            => 'photo_subscription',
			auth_info       => { auth_token => 123, username => 'abc' },
			client          => $client,
			subscription_id => 2,
			license         => 'premier_digital',
			unix_expiration_time => time + ( 60 * 60 * 24 * 7 ),
			sizes => { medium_jpg => { format => 'jpg', name => 'medium' } }
		),
		WebService::Shutterstock::Subscription->new(
			site            => 'video_subscription',
			auth_info       => { auth_token => 123, username => 'abc' },
			client          => $client,
			subscription_id => 3,
			license         => 'footage_standard',
			unix_expiration_time => time + ( 60 * 60 * 24 * 7 ),
			sizes => { lowres_mpeg => { format => 'mpeg', name => 'lowres' } }
		),
	]
);

isa_ok($customer, 'WebService::Shutterstock::Customer');

can_ok $customer, 'license_image';
can_ok $customer, 'license_video';

{
	my $guard = Test::MockModule->new('REST::Client');
	my $metadata;
	my $metadata_regex;
	$guard->mock('GET', sub {
		my $self = shift;
		return $self->response(
			response(200, encode_json({metadata_field_definitions => $metadata, account_id => 1}))
		);
	});
	$guard->mock('POST', sub {
		my($self, $url, $content) = @_;
		is $url, q{/subscriptions/2/images/1/sizes/medium.json}, 'correct URL';
		like $content, qr{format=jpg}, 'has format';
		like $content, qr{auth_token=123}, 'has auth_token';
		like $content, $metadata_regex, 'has metadata' if $metadata_regex;
		return $self->response(
			response(
				200,
				'{"photo_id":"14184","thumb_large":{"url":"http://thumb10.shutterstock.com/photos/thumb_large/yoga/IMG_0095.JPG","img":"http://thumb10.shutterstock.com/photos/thumb_large/yoga/IMG_0095.JPG"},"allotment_charge":0,"download":{"url":"http://download.shutterstock.com/gatekeeper/testing/shutterstock_1.jpg"}}
				'
			)
		);
	});
	eval {
		$customer->license_image(
			image_id     => 1,
			size         => 'bogus',
			subscription => { license => 'premier_digital' }
		);
		ok 0, 'should die';
		1;
	} or do {
		like $@, qr{Invalid size.*bogus}, 'errors on invalid size';
	};
	eval {
		delete $customer->{_info};
		$metadata = [{ name_api => 'foobar', is_required => 1 }];
		$customer->license_image(
			image_id     => 1,
			size         => 'medium',
			subscription => { license => 'premier_digital' }
		);
		ok 0, 'should die';
	} or do {
		like $@, qr{Missing required metadata.*foobar}, 'errors on missing metadata';
	};
	$metadata_regex = qr{metadata=%7B%22foobar};
	my $image = $customer->license_image(
		image_id     => 1,
		size         => 'medium',
		metadata     => { foobar => 'value' },
		subscription => { license => 'premier_digital' }
	);
	my $lwp = Test::MockModule->new('LWP::UserAgent');
	my $desired_dest;
	$lwp->mock('request', sub {
		my($self, $request, $dest) = @_;
		is $request->uri, 'http://download.shutterstock.com/gatekeeper/testing/shutterstock_1.jpg', 'has correct download URL';
		is $dest, $desired_dest, 'has correct destination: ' . ($dest || '[undef]');
		return response( 200, 'raw bytes' );
	});
	$image->download( file => $desired_dest = '/tmp/foo');
	$desired_dest = './shutterstock_1.jpg';
	is $image->download(directory => './'), $desired_dest, 'returns path to file';
	$desired_dest = undef;
	is $image->download, 'raw bytes', 'returns raw bytes';
}

{
	my $guard = Test::MockModule->new('REST::Client');
	my $metadata;
	my $metadata_regex;
	$guard->mock('GET', sub {
		my $self = shift;
		return $self->response(
			response(200, encode_json({metadata_field_definitions => $metadata, account_id => 1}))
		);
	});
	$guard->mock('POST', sub {
		my($self, $url, $content) = @_;
		is $url, q{/subscriptions/3/videos/12345/sizes/lowres.json}, 'correct URL';
		like $content, qr{auth_token=123}, 'has auth_token';
		like $content, $metadata_regex, 'has metadata' if $metadata_regex;
		return $self->response(
			response(
				200,
				'{"download":{"url":"http://download.dev.shutterstock.com/gatekeeper/W3siZSI6MTM1Nzg2NTA2NSwiayI6InZpZGVvLzEyMy9sb3dyZXMubXBnIiwibSI6IjEiLCJkIjoic2h1dHRlcnN0b2NrLW1lZGlhIn0sIklQWEpJSDF6Uk1lU2t5R0FKOHB5V3lvbU0vTSJd/shutterstock_v12345.mpg"}}
				'
			)
		);
	});
	eval {
		$customer->license_video( video_id => 12345, subscription => 2 );
		ok 0, 'should die';
		1;
	} or do {
		like $@, qr{wrong "site"}, 'has correct error';
	};
	my $licensed_video = $customer->license_video( video_id => 12345, subscription => { id => 3 }, metadata => { foobar => 1 } );
	isa_ok($licensed_video,'WebService::Shutterstock::LicensedVideo');
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
