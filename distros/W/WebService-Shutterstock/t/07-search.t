use strict;
use warnings;
use Test::More;
use WebService::Shutterstock;
use Test::MockModule;

my $ss = WebService::Shutterstock->new(api_username => "test", api_key => 123);

can_ok $ss, 'search';
subtest 'image search' => sub {
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my $self = shift;
		like $_[0], qr{^/images/search.json}, 'GETs correct URL';
		like $_[0], qr{searchterm=cat},       'has correct search term';
		my ($page) = $_[0] =~ m/page_number=(\d+)/;
		$ss->client->response(
			response(
				200,
				[ 'Content-Type' => 'application/json' ],
				'{"count":"9337","page":"'
				  . ( $page || 0 )
				  . '","searchSrcID":"","sort_method":"popular","results":[{"photo_id":1},{"photo_id":2}]}'
			)
		);
	});
	my $search = $ss->search(searchterm => 'cat');
	is $search->count, 9337, 'has count';
	is $search->sort_method, 'popular', 'has sort_method';
	is $search->page, 0, 'first page';
	$search = $search->next_page;
	is $search->page, 1, 'next page';
	my $results = $search->results;
	is @$results, 2, 'has correct number of results';
	my $image = $results->[0]->image;
	is $image->id, 1, 'has correct image ID';
};

subtest 'video search' => sub {
	my $guard = Test::MockModule->new('REST::Client');
	$guard->mock('GET', sub {
		my $self = shift;
		like $_[0], qr{^/videos/search.json}, 'GETs correct URL';
		like $_[0], qr{searchterm=cat},       'has correct search term';
		my ($page) = $_[0] =~ m/page_number=(\d+)/;
		$ss->client->response(
			response(
				200,
				[ 'Content-Type' => 'application/json' ],
				'{"count":"9337","page":"'
				  . ( $page || 0 )
				  . '","searchSrcID":"","sort_method":"popular","results":[{"video_id":1,"sizes":{"thumb_video":{"webm_url":"foo","mp4_url":"bar"}},"aspect_ratio_common":"4:3"},{"video_id":2}]}'
			)
		);
	});
	my $search = $ss->search(searchterm => 'cat', type => 'video');
	is $search->count, 9337, 'has count';
	is $search->sort_method, 'popular', 'has sort_method';
	is $search->page, 0, 'first page';
	$search = $search->next_page;
	is $search->page, 1, 'next page';
	my $results = $search->results;
	is @$results, 2, 'has correct number of results';
	isa_ok $results->[0]->thumb_video, 'HASH', 'has hashref of thumb_video info';
	my $video = $results->[0]->video;
	is $video->id, 1, 'has correct video ID';
	is $video->aspect_ratio_common, '4:3', 'uses value returned from search result';
};

subtest 'iterator' => sub {
	my $guard = Test::MockModule->new('REST::Client');
	my @results = (
		'[{"photo_id":1},{"photo_id":2}]',
		'[{"photo_id":3},{"photo_id":4}]',
		'[{"photo_id":5},{"photo_id":6}]',
	);
	my $total = @results * 2;
	$guard->mock('GET', sub {
		my $self = shift;
		like $_[0], qr{^/images/search.json}, 'GETs correct URL';
		like $_[0], qr{searchterm=cat},       'has correct search term';
		my ($page) = $_[0] =~ m/page_number=(\d+)/;
		$page ||= 0;
		$ss->client->response(
			response(
				200,
				[ 'Content-Type' => 'application/json' ],
				qq({"count":"$total","page":"$page","searchSrcID":"","sort_method":"popular","results":) . ($results[$page] || '[]') . '}'
			)
		);
	});
	my $search = $ss->search(searchterm => 'cat', type => 'image');
	is $search->count, 6, 'has count';
	is $search->page, 0, 'first page';
	can_ok($search,'iterator');
	my $iterator = $search->iterator();
	isa_ok($iterator,'CODE');
	is $iterator->()->photo_id, 1, 'first item (first page)';
	is $iterator->()->photo_id, 2, 'second item (first page)';
	is $iterator->()->photo_id, 3, 'third item (second page)';
	is $iterator->()->photo_id, 4, 'fourth item (second page)';
	is $iterator->()->photo_id, 5, 'fifth item (third page)';
	is $iterator->()->photo_id, 6, 'last item (third page)';
	is $iterator->(), undef, 'no more items';
	is $iterator->(), undef, 'still no more items';
};

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
