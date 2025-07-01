package WebService::TogetherWeRemember::v0::API;

use 5.006;
use strict;
use warnings;

use Moo;
use URI;
use LWP::UserAgent;
use HTTP::CookieJar::LWP;
use Cpanel::JSON::XS;
use File::Basename;
use IO::File;

has json => (
	is => 'ro',
	default => sub {
		return Cpanel::JSON::XS->new->utf8->pretty(1)->allow_nonref;
	}
);

has ua => (
	is => 'ro',
	default => sub {
		my $jar = HTTP::CookieJar::LWP->new;
		my $ua = LWP::UserAgent->new(cookie_jar => $jar);
		return $ua;
	}
);

has host => (
	is => 'ro',
	default => sub {
		return 'https://togetherweremember.com';
  	} 
);

sub _request {
  	my ($self, $method, $path, $params) = @_;
  	my $url = URI->new($self->host . $path);
  	my $response;

  	if ($method eq 'GET') {
		$url->query_form(%$params) if $params;
		$response = $self->ua->get($url);
  	} elsif ($method eq 'POST') {
		my $content = [ ];

		if ($params->{related_links}) {
			my $related = delete $params->{related_links};
			push @{$content}, map {
				$_->{url} ? ('related_link[]' => $_->{url}, 'related_link_label[]' => $_->{label}) : ()
			} @$related;
		}

		if ($params->{existing_image_ids}) {
			my $existing = delete $params->{existing_image_ids};
			for (@{$existing}) {
				push @{$content}, "existing_image_ids[]" => $_;
			}
		}

		push @{$content}, map { $_ => $params->{$_} } keys %$params;

		$response = $self->ua->post($url, Content_Type => 'form-data', Content => $content);
  	} else {
		die "Unsupported HTTP method: $method";
  	}

  	return $self->_parse_response($response);
}

sub _parse_response {
  	my ($self, $response) = @_;
  	if ($response->is_success) {
		return $self->json->decode($response->decoded_content);
  	} else {
		return { ok => 0, error => $response->status_line };
  	}
}

sub login {
  	my ($self, $email, $password) = @_;
  	my $url = '/api/login';
  	my $response = $self->_request('POST',
		$url,
		{
			email    => $email,
			password => $password,
		}
	);
	return $response;
}

sub logout {
  	my ($self) = @_;
  	my $url = '/api/logout';
  	my $response = $self->_request('GET', $url, ());
	return $response;
}

sub user_get {
  	my ($self, $user_id) = @_;
  	my $url = "/api/user/get";
	$url .= '/' . $user_id if ($user_id);
  	my $response = $self->_request('GET', $url, ());
	return $response;
}

sub user_update {
  	my ($self, $data) = @_;
  	my $url = "/api/user/update";
	if ($data->{profile_image} && ! ref $data->{profile_image}) {
		$data->{profile_image} = [ $data->{profile_image} ];
	}
  	my $response = $self->_request('POST', $url, $data);
	return $response;
}

sub timelines_published {
	my ($self, $user_id, $params) = @_;
	my $url = '/api/timeline/published';
	$url .= '/' . $user_id if ($user_id);
	my $response = $self->_request('GET', $url, $params);
	return $response;
}

sub timelines_mine {
	my ($self, $params) = @_;
	my $url = '/api/timelines/mine';
	my $response = $self->_request('GET', $url, $params);
	return $response;
}

sub timelines_collab {
	my ($self, $params) = @_;
	my $url = '/api/timelines/collab';
	my $response = $self->_request('GET', $url, $params);
	return $response;
} 

sub timelines_liked {
	my ($self, $params) = @_;
	my $url = '/api/timelines/liked';
	my $response = $self->_request('GET', $url, $params);
	return $response;
}

sub timeline_passphrase {
	my ($self, $timeline_id, $passphrase) = @_;
	
	if (!$timeline_id) {
		die "timeline id is required";	
	}

	if (!$passphrase) {
		die "passphrase is required";
	}

	my $url = '/api/timeline/passphrase';
	my $response = $self->_request('POST', $url, {
		timeline_id => $timeline_id,
		passphrase => $passphrase
	});
	return $response;
}

sub timeline_get {
	my ($self, $timeline_id) = @_;
	if (! $timeline_id) {
		die 'Timeline ID is required for getting a timeline';
	}
	my $url = "/api/timeline/get/$timeline_id";
	my $response = $self->_request('GET', $url, {});
	return $response;
}

sub timeline_create {
	my ($self, $data) = @_;

	if (! $data->{name}) {
		die 'Name is required for creating a timeline';
	}

	if (! $data->{description}) {
		die 'Description is required for creating a timeline';
	}

	if ($data->{image} && ! ref $data->{image}) {
		$data->{image} = [ $data->{image} ];
	}

	my $url = '/api/timeline/create';
	my $response = $self->_request('POST', $url, $data);
	return $response;
}

sub timeline_update {
	my ($self, $data) = @_;

	if (! $data->{id}) {
		die 'Timeline ID is required for updating a timeline';
	}

	if (! $data->{name}) {
		die 'Name is required for updating a timeline';
	}

	if (! $data->{description}) {
		die 'Description is required for updating a timeline';
	}

	if ($data->{image} && ! ref $data->{image}) {
		$data->{image} = [ $data->{image} ];
	}

	my $url = '/api/timeline/update';
	my $response = $self->_request('POST', $url, $data);
	return $response;
}

sub timeline_delete {
	my ($self, $timeline_id) = @_;
	if (! $timeline_id) {
		die 'Timeline ID is required for deleting a timeline';
	}
	my $url = "/api/timeline/delete/$timeline_id";
	my $response = $self->_request('POST', $url, {});
	return $response;
}

sub memory_list {
	my ($self, $timeline_id, $params) = @_;
	$params ||= {};
	if (! $timeline_id) {
		die 'Timeline ID is required for getting memories';
	}
	$params->{timeline_id} = $timeline_id;
	my $url = '/api/timeline/item/list';
	my $response = $self->_request('GET', $url, $params);
	return $response;
}

sub memory_get {
	my ($self, $timeline_id, $memory_id, $params) = @_;
	$params ||= {};
	if (! $timeline_id) {
		die 'Timeline ID is required for getting a memory';
	}

	if (! $memory_id) {
		die 'Memory ID is required for getting a memory';
	}

	$params->{timeline_id} = $timeline_id;
	$params->{memory_id} = $memory_id;
	my $url = "/api/timeline/item/get";
	my $response = $self->_request('GET', $url, $params);
	return $response;
}

sub memory_create {
	my ($self, $timeline_id, $data) = @_;
	
	if (! $timeline_id) {
		die 'Timeline ID is required for creating a memory';
	}
	if (! $data->{title}) {
		die 'Title is required for creating a memory';
	}
	$data->{timeline_id} = $timeline_id;
	$data->{date} ||= time;

	my $url = '/api/timeline/item/save';
	my $response = $self->_request('POST', $url, $data);
	return $response;
}

sub memory_update {
	my ($self, $timline_id, $memory_id, $data) = @_;
	if (! $timline_id) {
		die 'Timeline ID is required for updating a memory';
	}
	if (! $memory_id) {
		die 'Memory ID is required for updating a memory';
	}
	if (! $data->{title}) {
		die 'Title is required for updating a memory';
	}

	if ($data->{images}) {
		$data->{existing_image_ids} = [ map { $_->{id} } @{delete $data->{images}} ];
	}

	if ($data->{event_epoch}) {
		$data->{date} = delete $data->{event_epoch};
	}

	$data->{timeline_id} = $timline_id;
	$data->{memory_id} = $memory_id;
	$data->{date} ||= time;
	my $url = '/api/timeline/item/save';
	my $response = $self->_request('POST', $url, $data);
	return $response;
}

sub memory_asset {
	my ($self, $timeline_id, $memory_id, $file, $chunk_size) = @_;

	if (! $timeline_id) {
		die 'Timeline ID is required for uploading a memory asset';
	}
	if (! $memory_id) {
		die 'Memory ID is required for uploading a memory asset';
	}
	if (! $file || ! -e $file) {
		die 'Valid file path is required for uploading a memory asset';
	}

	$chunk_size ||= 5 * 1024 * 1024; # 5MB per chunk
	my $fh = IO::File->new($file, 'r') or die "Cannot open file $file: $!";
	binmode $fh;

	my $filesize = -s $file;
	my $total_chunks = int(($filesize + $chunk_size - 1) / $chunk_size);
	my $filename = basename($file);

	my @results;
	for (my $chunk_index = 0; $chunk_index < $total_chunks; $chunk_index++) {
		seek($fh, $chunk_index * $chunk_size, 0);
		my $read_size = ($chunk_index == $total_chunks - 1)
			? $filesize - $chunk_index * $chunk_size
			: $chunk_size;
		my $buffer;
		my $read = read($fh, $buffer, $read_size);
		die "Failed to read chunk $chunk_index" unless defined $read && $read == $read_size;

		my $url = '/api/timeline/item/asset';
		my $response = $self->ua->post(
			$self->host . $url,
			Content_Type => 'form-data',
			Content => [
				timeline_id  => $timeline_id,
				memory_id    => $memory_id,
				total_chunks => $total_chunks,
				chunk_index  => $chunk_index,
				file         => [
					undef, $filename,
					Content_Type => 'application/octet-stream',
					Content      => $buffer,
				],
			]
		);

		push @results, $self->_parse_response($response);
	}

	$fh->close;
	return \@results;
}

sub memory_delete {
	my ($self, $timeline_id, $memory_id) = @_;

	if (! $timeline_id) {
		die 'Timeline ID is required for deleting a memory';
	}
	if (! $memory_id) {
		die 'Memory ID is required for deleting a memory';
	}
	my $url = '/api/timeline/item/delete';
	my $response = $self->_request('POST', $url, {
		timeline_id => $timeline_id,
		memory_id   => $memory_id,
	});
	return $response;
}

1;

=head1 NAME

WebService::TogetherWeRemember::v0::API - Perl interface for TogetherWeRemember API v0

=head1 DESCRIPTION

Together We Remember is a platform where you can create, share, and preserve meaningful memories.

This document outlines the v0 version of the Together We Remember API.

The API is free to use, but you must first create a user account and know your password to authenticate and access the endpoints.

L<Together We Remember|https://togetherweremember.com>

=head1 SYNOPSIS

	use WebService::TogetherWeRemember;

	my $twr = WebService::TogetherWeRemember->new();

	my $api = $twr->login($email, $password);

	my $timeline = $api->timeline_create({
		name => "My First Timeline",
		description => $markdown_text,
		image => '/path/to/image.png',
		related_links => [
			{ label => "lnation", url => "https//lnation.org" }
		],
		passphrase => "123",
		is_public => 1,
		is_published => 0,
		is_open => 0,
	});

	my $memory = $api->memory_create($timline->{timeline}->{id}, {
		title => "My First Memory",
		content => $markdown_text,
		date => time,
		related_links => [
			{ label => "lnation", url => "https//lnation.org" }
		],
	});

	$api->memory_asset($timeline->{timeline}->{id}, $memory->{memory}->{id}, '/path/to/asset.mp4', 5 * 1024 * 1024);

	$api->logout();

=head1 DESCRIPTION

This module provides a Perl interface to the TogetherWeRemember API (version 0).

=head1 ATTRIBUTES

=head2 ua

L<LWP::UserAgent> instance used for HTTP requests.

=head2 host

Base URL for the API.

=head1 AUTHENTICATION

=head2 login

	my $response = $api->login($email, $password);

This method sends a login request to the TogetherWeRemember API with the provided email and password. It returns the HTTP response.

=over 4

=item *

URL: C<POST /api/login>

=item *

Parameters:

=over 8

=item * C<email> (string) - The user's email address.

=item * C<password> (string) - The user's password.

=back

=back

This method sends a form data POST request to C</api/login> with the above parameters.

=cut

=head2 logout

	my $response = $api->logout();

This method sends a logout request to the TogetherWeRemember API. It returns the HTTP response.

=over 4

=item *

URL: C<GET /api/logout>

=item *

This method does not require any parameters.

=back

This method sends a GET request to C</api/logout>.

=cut

=head1 USERS

=head2 user_get

	my $response = $api->user_get($user_id);

This method retrieves user information from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/user/get>
	C<GET /api/user/get/:userid>

=item *

Parameters:

=over 2

=item * C<userid> (string) - The user's id.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<user> (hash) - users data if successful.

=back

=back

=cut

=head2 user_update

	my $response = $api->user_update({
		name => 'My Name',
		bio => $markdown_bio,
		profile_image => '/path/to/image.png'
	});

This method updates user information in the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/user/update>

=item *

Parameters:

=over 2

=item * C<profile_image> (string or array) - The user's profile image. If a string is provided, it will be converted to an array.

=item * C<name> (string) - The user's name.

=item * C<bio> (string) - The user's biography.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=back

=back

This method sends a form data POST request to C</api/user/update> with the provided user data.

=cut

=head1 TIMELINES

=head2 timelines_published

	my $response = $api->timelines_published($user_id, { page => 1, q => 'search text' });

This method retrieves published timelines from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timeline/published>
	C<GET /api/timeline/published/:userid>

=item *

Parameters:

=over 2

=item * C<userid> (string, optional) - The user's id. If provided, only timelines for this user will be returned.

=item * C<page> (integer, optional) - The page number for pagination.

=item * C<q> (string, optional) - Search query to filter timelines.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timelines> (array) - List of timelines if successful.

=back

=back

This method sends a GET request to C</api/timeline/published> with the provided parameters.

=cut

=head2 timelines_mine

	my $response = $api->timelines_mine({ page => 0, limit => 10 });

This method retrieves the user's own timelines from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timelines/mine>

=item *

Parameters:

=over 2

=item * C<page> (integer, optional) - The page number for pagination. Default is 0.

=item * C<limit> (integer, optional) - The number of timelines to return per page. Default is 12.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timelines> (array) - List of timelines if successful.

=back

=back

This method sends a GET request to C</api/timelines/mine> with the provided parameters.

=cut

=head2 timelines_collab

	my $response = $api->timelines_collab({ page => 0, limit => 10 });

This method retrieves timelines where the user is a collaborator from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timelines/collab>

=item *

Parameters:

=over 2

=item * C<page> (integer, optional) - The page number for pagination. Default is 0.

=item * C<limit> (integer, optional) - The number of timelines to return per page. Default is 12.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timelines> (array) - List of timelines if successful.

=back

=back

This method sends a GET request to C</api/timelines/collab> with the provided parameters.

=cut

=head2 timelines_liked

	my $response = $api->timelines_liked({ page => 0, limit => 10 });

This method retrieves timelines that the user has liked from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timelines/liked>

=item *

Parameters:

=over 2

=item * C<page> (integer, optional) - The page number for pagination. Default is 0.

=item * C<limit> (integer, optional) - The number of timelines to return per page. Default is 12.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timelines> (array) - List of timelines if successful.

=back

=back

This method sends a GET request to C</api/timelines/liked> with the provided parameters.

=cut

=head2 timeline_passphrase

	my $response = $api->timeline_passphrase($timeline_id, $passphrase);

This method authenticates you to access a timeline that has a passphrase attached to it. You will not need to use the passphrase for your own timelines only for collaborative.

=over 4

=item *

=item *

URL: C<POST /api/timeline/passphrase>

=item *

Parameters:

=over 2

=item * C<timeline_id> (string, required) - The ID of the timeline to access.

=item * C<passphrase> (string, required) - The passphrase for the timeline.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timeline> (hash) - The timeline data if successful.

=back

=back

This method sends a form data POST request to C</api/timeline/passphrase> with the provided timeline ID and passphrase.

=cut

=head2 timeline_get

	my $response = $api->timeline_get($timeline_id);

This method retrieves a specific timeline from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timeline/get/:timelineid>

=item *

Parameters:

=over 2

=item * C<timelineid> (string, required) - The ID of the timeline to retrieve.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timeline> (hash) - The timeline data if successful.

=back

=back

This method sends a GET request to C</api/timeline/get/:timelineid> with the provided timeline ID.

=cut

=head2 timeline_create

	my $response = $api->timeline_create({
		name => 'My Timeline',
		description => 'A description of my timeline',
		image => '/path/to/image.png',
		related_links => [
			{ url => 'https://lnation.org', label => 'LNATION' },
			{ url => 'https://example.com', label => 'Example' }
		],
		passphrase => '123',
		is_public => 1,
		is_published => 0,
		is_open => 0,
	});

This method creates a new timeline in the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/create>

=item *

Parameters:

=over 2

=item * C<name> (string, required) - The name of the timeline.

=item * C<description> (string, optional) - A description of the timeline.

=item * C<image> (string, optional) - The path to the timeline image.

=item * C<related_links> (array, optional) - An array of related links, each containing a C<url> and a C<label>.

=item * C<passphrase> (string, optional) - A passphrase for the timeline.

=item * C<is_public> (boolean, optional) - Whether the timeline is public. Default is 1 (true).

=item * C<is_published> (boolean, optional) - Whether the timeline is published. Default is 0 (false).

=item * C<is_open> (boolean, optional) - Whether the timeline is open for collaboration. Default is 0 (false).

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timeline> (hash) - The created timeline data if successful.

=back

=back

This method sends a form data POST request to C</api/timeline/create> with the provided timeline data.

=cut

=head2 timeline_update

	my $response = $api->timeline_update({
		id => '12345',
		name => 'Updated Timeline Name',
		description => 'Updated description of the timeline',
		image => '/path/to/new_image.png',
		related_links => [
			{ url => 'https://lnation.org', label => 'LNATION' },
			{ url => 'https://example.com', label => 'Example' }
		],
		passphrase => 'newpassphrase',
		is_public => 1,
		is_published => 1,
		is_open => 1,
	});

This method updates an existing timeline in the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/update>

=item *

Parameters:

=over 2

=item * C<id> (string, required) - The ID of the timeline to update.

=item * C<name> (string, required) - The new name of the timeline.

=item * C<description> (string, optional) - The new description of the timeline.

=item * C<image> (string, optional) - The path to the new timeline image.

=item * C<related_links> (array, optional) - An array of related links, each containing a C<url> and a C<label>.

=item * C<passphrase> (string, optional) - A new passphrase for the timeline.

=item * C<is_public> (boolean, optional) - Whether the timeline is public. Default is 1 (true).

=item * C<is_published> (boolean, optional) - Whether the timeline is published. Default is 1 (true).

=item * C<is_open> (boolean, optional) - Whether the timeline is open for collaboration. Default is 1 (true).

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<timeline> (hash) - The updated timeline data if successful.

=back

=back

This method sends a form data POST request to C</api/timeline/update> with the provided timeline data.

=cut

=head2 timeline_delete

	my $response = $api->timeline_delete($timeline_id);

This method deletes a timeline from the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/delete/:timelineid>

=item *

Parameters:

=over 2

=item * C<timelineid> (string, required) - The ID of the timeline to delete.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<message> (string) - A message indicating the result of the deletion.

=back

=back

This method sends a POST request to C</api/timeline/delete/:timelineid> with the provided timeline ID.

=cut

=head1 MEMRORIES

=head2 memory_list

	my $response = $api->memory_list($timeline_id, { 
		page => 0,
		limit => 10,
		orderby => 'event_date',
		orderdir => 'desc',
		from => 1751026816, # Unix timestamp
		to => 1751026920,   # Unix timestamp
		q => 'search text'
	});

This method retrieves a list of memories (timeline items) for a given timeline from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timeline/item/list>

=item *

Parameters:

=over 2

=item * C<timelineid> (string, required) - The ID of the timeline.

=item * C<page> (integer, optional) - The page number for pagination. Default is 0.

=item * C<limit> (integer, optional) - The number of items per page. Default is 12.

=item * C<orderby> (string, optional) - Field to order by (e.g., 'event_date').

=item * C<orderdir> (string, optional) - Order direction ('asc' or 'desc').

=item * C<from> (integer, optional) - Start of date range (Unix timestamp).

=item * C<to> (integer, optional) - End of date range (Unix timestamp).

=item * C<q> (string, optional) - Search query to filter memories.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<memories> (array) - List of memory items if successful.

=back

=back

This method sends a GET request to C</api/timeline/item/list> with the provided parameters.

=cut

=head2 memory_get

	my $response = $api->memory_get($timeline_id, $memory_id);

This method retrieves a specific memory (timeline item) from the TogetherWeRemember API.

=over 4

=item *

URL: C<GET /api/timeline/item/get>

=item *

Parameters:

=over 2

=item * C<timelineid> (string, required) - The ID of the timeline.

=item * C<memoryid> (string, required) - The ID of the memory to retrieve.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<memory> (hash) - The memory data if successful.

=back

=back

This method sends a GET request to C</api/timeline/item/get> with the provided timeline ID and memory ID.

=cut

=head2 memory_create

	my $response = $api->memory_create($timeline_id, {
		title => 'My Memory Title',
		content => 'A description of my memory',
		date => epoch,
		related_links => [
			{ url => 'https://lnation.org', label => 'LNATION' },
			{ url => 'https://example.com', label => 'Example' }
		],
	});

This method creates a new memory (timeline item) in the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/item/save>

=item *

Parameters:

=over 2

=item * C<timeline_id> (string, required) - The ID of the timeline to add the memory to.

=item * C<title> (string, required) - The title of the memory.

=item * C<content> (string, optional) - The content or description of the memory.

=item * C<date> (integer, optional) - The event date as a Unix timestamp.

=item * C<related_links> (array, optional) - An array of related links, each containing a C<url> and a C<label>.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<memory> (hash) - The created memory data if successful.

=back

=back

This method sends a form data POST request to C</api/timeline/item/save> with the provided memory data.

=cut

=head2 memory_update

	my $response = $api->memory_update($timeline_id, $memory_id, {
		title => 'Updated Memory Title',
		content => 'Updated description of my memory',
		date => epoch,
		existing_image_ids => [ 10, 15 ],
		related_links => [
			{ url => 'https://lnation.org', label => 'LNATION' },
			{ url => 'https://example.com', label => 'Example' }
		],
	});

This method updates an existing memory (timeline item) in the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/item/save>

=item *

Parameters:

=over 2

=item * C<timeline_id> (string, required) - The ID of the timeline containing the memory.

=item * C<memory_id> (string, required) - The ID of the memory to update.

=item * C<title> (string, required) - The new title of the memory.

=item * C<content> (string, optional) - The new content or description of the memory.

=item * C<date> (integer, optional) - The new event date as a Unix timestamp.

=item * C<existing_image_ids> (array, optional) - Array of image IDs to retain.

=item * C<related_links> (array, optional) - An array of related links, each containing a C<url> and a C<label>.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=item * C<memory> (hash) - The updated memory data if successful.

=back

=back

This method sends a form data POST request to C</api/timeline/item/save> with the provided memory data.

=cut

=head2 memory_asset

	my $response = $api->memory_asset($timeline_id, $memory_id, '/path/to/asset.mp4', 5 * 1024 * 1024);

This method uploads an asset (file) to a specific memory in the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/item/asset>

=item *

Parameters:

=over 2

=item * C<timeline_id> (string, required) - The ID of the timeline containing the memory.

=item * C<memory_id> (string, required) - The ID of the memory to which the asset will be uploaded.

=item * C<file> (string, required) - The path to the file to upload.

=item * C<chunk_size> (integer, optional) - The size of each chunk to upload. Default is 5MB.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful for each chunk.

=item * C<results> (array) - An array of responses for each uploaded chunk.

=back

=back

This method uploads the specified file in chunks (default 5MB each) to C</api/timeline/item/asset> for the given timeline and memory. Each chunk is sent as a separate POST request with multipart form data.

=cut

=head2 memory_delete

	my $response = $api->memory_delete($timeline_id, $memory_id);

This method deletes a specific memory (timeline item) from the TogetherWeRemember API.

=over 4

=item *

URL: C<POST /api/timeline/item/delete>

=item *

Parameters:

=over 2

=item * C<timeline_id> (string, required) - The ID of the timeline containing the memory.

=item * C<memory_id> (string, required) - The ID of the memory to delete.

=back

=item *

Returns:

=over 1

=item * C<ok> (boolean) - Indicates if the request was successful.

=back

=back

This method sends a POST request to C</api/timeline/item/delete> with the provided timeline ID and memory ID.

=cut

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut
