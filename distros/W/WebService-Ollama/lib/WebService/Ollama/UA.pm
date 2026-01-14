package WebService::Ollama::UA;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.08';

use Moo;
use LWP::UserAgent;
use JSON::Lines;
use MIME::Base64 qw/encode_base64/;
use URI;

use WebService::Ollama::Response;

has base_url => (
	is => 'ro',
);

has ua => (
	is => 'ro',
	default => sub {
		LWP::UserAgent->new();
	}
);

has json => (
	is => 'ro',
	default => sub {
		JSON::Lines->new( utf8 => 1 );
	}
);

sub get {
	shift->request(
		type => 'GET',
		@_
	);
}

sub post {
	shift->request(
		type => 'POST',
		@_
	);
}

sub delete {
	shift->request(
		type => 'DELETE',
		@_
	);
}

sub request {
	my ($self, %params) = @_;
	my $url = URI->new($self->base_url . $params{url});
	my $res;

	my $stream_cb = delete $params{data}{stream_cb};
	$self->ua->remove_handler();
	if ($stream_cb) {
		$self->ua->add_handler(response_data => sub {
			my($response, $ua, $handler, $data) = @_; 
			$data = $self->json->decode($data);
			for (@{$data}) {
				$stream_cb->(WebService::Ollama::Response->new(%{$_}));
			}
			return 1;
		});
	}

	if ($params{type} eq 'GET') { 
		$url->query_form($params{data});
		$res = $self->ua->get($url);
	} elsif ($params{type} eq 'DELETE') {
		$res = $self->ua->delete(
			$url,
			content => $self->json->encode([$params{data}]), 
			'Content-Type' => 'application/json'
		);
	} else {
		$res = $self->ua->post(
			$url, 
			content => $self->json->encode([$params{data}]), 
			'Content-Type' => 'application/json'
		);
	}
	return $self->response($res);
}

sub response {
	my ($self, $res) = @_;

	if ($res->is_success) {
		my $content = $self->json->decode($res->decoded_content);
		my @res = map {
			WebService::Ollama::Response->new(%{$_})
		} @{$content};
		return scalar @res == 1 ? $res[0] : \@res;
	}
	 
	die $res->decoded_content;
}

sub base64_images {
	my ($self, $images) = @_;

	my @out;
	for my $image (@{$images}) {
		open my $fh, '<', $image;
		my $content = do { local $/; <$fh> };
		close $fh;
		push @out, encode_base64($content);
	}
	return \@out;
}

1;

__END__

=head1 NAME

WebService::Ollama::UA - HTTP client for Ollama

=head1 VERSION

Version 0.08

=head1 SYNOPSIS

    use WebService::Ollama::UA;

    my $ua = WebService::Ollama::UA->new(
        base_url => 'http://localhost:11434',
    );

    my $response = $ua->get(url => '/api/version');
    my $response = $ua->post(url => '/api/chat', data => \%args);

=head1 DESCRIPTION

HTTP user agent for WebService::Ollama using LWP::UserAgent.
Handles JSON encoding/decoding and response parsing.

=head1 METHODS

=head2 new

    my $ua = WebService::Ollama::UA->new(
        base_url => 'http://localhost:11434',
    );

=head2 get

    my $response = $ua->get(url => '/api/version');

Perform a GET request.

=head2 post

    my $response = $ua->post(url => '/api/chat', data => \%args);

Perform a POST request with JSON body.

=head2 delete

    my $response = $ua->delete(url => '/api/delete', data => \%args);

Perform a DELETE request.

=head2 base64_images

    my $images = $ua->base64_images(['path/to/image.png']);

Convert image files to base64 encoding for multimodal models.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
