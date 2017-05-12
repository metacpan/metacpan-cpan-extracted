use strict;
use warnings;
use Test::More;
use WebService::Shutterstock::Image;
use Test::MockModule;
use WebService::Shutterstock::Client;

my $image = WebService::Shutterstock::Image->new( client => WebService::Shutterstock::Client->new, image_id => 1, sizes => {"huge" => {width => 1, height => 2}});
isa_ok($image, 'WebService::Shutterstock::Image');

ok $image->size('huge'), 'has huge size';
ok !$image->size('blah'), 'no blah size';

{
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my $self = shift;
		is $_[0], '/images/1/similar.json', 'GET URL';
		$image->client->response(response(200, ['Content-Type' => 'application/json'], '[{"image_id":2}]'));
	});
	my $similar_images = $image->similar;
	is @$similar_images, 1, 'has one similar image';
	is $similar_images->[0]->id, 2, 'has correct similar image';
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
