package WebService::Ollama::UA;

use Moo;
use LWP::UserAgent;
use JSON::Lines;
use MIME::Base64 qw/encode_base64/;

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
