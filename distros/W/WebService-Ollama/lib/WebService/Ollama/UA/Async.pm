package WebService::Ollama::UA::Async;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

use Moo;
use Future;
use IO::Async::Loop;
use Net::Async::HTTP;
use JSON::Lines;
use MIME::Base64 qw(encode_base64);
use URI;

use WebService::Ollama::Response;

has json => (
	is => 'ro',
	default => sub {
		JSON::Lines->new( utf8 => 1 );
	}
);

has base_url => (
	is => 'ro',
	required => 1,
);

has loop => (
	is => 'ro',
	lazy => 1,
	default => sub { IO::Async::Loop->new },
);

has http => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		my $http = Net::Async::HTTP->new(
			max_connections_per_host => 4,
			timeout => 300,  # 5 min timeout for LLM responses
		);
		$self->loop->add($http);
		return $http;
	},
);

sub get {
	my ($self, %params) = @_;
	return $self->request(type => 'GET', %params);
}

sub post {
	my ($self, %params) = @_;
	return $self->request(type => 'POST', %params);
}

sub delete {
	my ($self, %params) = @_;
	return $self->request(type => 'DELETE', %params);
}

sub request {
	my ($self, %params) = @_;

	my $url = URI->new($self->base_url . $params{url});
	my $method = $params{type} // 'GET';
	my $data = $params{data} // {};

	# Remove stream_cb - async doesn't use callbacks the same way
	delete $data->{stream_cb};

	my %request_params = (
		method => $method,
		uri    => $url,
	);

	if ($method eq 'GET') {
		$url->query_form(%$data) if keys %$data;
		$request_params{uri} = $url;
	} else {
		$request_params{content_type} = 'application/json';
		$request_params{content} = $self->json->encode([$data]);
	}

	return $self->http->do_request(%request_params)->then(sub {
		my ($response) = @_;

		if ($response->is_success) {
			my $content = $response->decoded_content;
			my $decoded = eval { $self->json->decode($content) };
			if ($@) {
				return Future->fail("JSON decode error: $@");
			}

			# Handle array vs single response
			if (ref($decoded) eq 'ARRAY') {
				my @responses = map {
					WebService::Ollama::Response->new(%$_)
				} @$decoded;
				return Future->done(
					scalar @responses == 1 ? $responses[0] : \@responses
				);
			} else {
				return Future->done(
					WebService::Ollama::Response->new(%$decoded)
				);
			}
		} else {
			return Future->fail(
				"HTTP error: " . $response->status_line . " - " . $response->decoded_content
			);
		}
	});
}

sub base64_images {
	my ($self, $images) = @_;

	my @out;
	for my $image (@$images) {
		open my $fh, '<:raw', $image or die "Cannot open $image: $!";
		my $content = do { local $/; <$fh> };
		close $fh;
		push @out, encode_base64($content, '');
	}
	return \@out;
}

1;

__END__

=head1 NAME

WebService::Ollama::UA::Async - Async HTTP client for Ollama

=head1 SYNOPSIS

    use WebService::Ollama::UA::Async;
    use IO::Async::Loop;

    my $loop = IO::Async::Loop->new;
    my $ua = WebService::Ollama::UA::Async->new(
        base_url => 'http://localhost:11434',
        loop     => $loop,
    );

    my $future = $ua->post(
        url  => '/api/chat',
        data => { model => 'llama3', messages => [...] },
    );

    $future->then(sub {
        my ($response) = @_;
        print $response->message->{content};
    })->get;

=head1 DESCRIPTION

Async HTTP user agent for WebService::Ollama using IO::Async and Net::Async::HTTP.
All request methods return Future objects.

=head1 METHODS

=head2 get

    my $future = $ua->get(url => '/api/version');

=head2 post

    my $future = $ua->post(url => '/api/chat', data => \%args);

=head2 delete

    my $future = $ua->delete(url => '/api/delete', data => \%args);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.
This is free software, licensed under The Artistic License 2.0.

=cut
