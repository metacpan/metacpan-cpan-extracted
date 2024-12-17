package WebService::Chroma::UA;

use Moo;
use LWP::UserAgent;
use JSON;

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
		JSON->new;
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
	if ($params{type} eq 'GET') { 
		$url->query_form($params{data});
		$res = $self->ua->get($url);
	} elsif ($params{type} eq 'DELETE') {
		$url->query_form($params{data});
		$res = $self->ua->delete($url);
	} else {
		$res = $self->ua->post(
			$url, 
			content => $self->json->encode($params{data}), 
			'Content-Type' => 'application/json'
		);
	}
	return $self->response($res);
}

sub response {
	my ($self, $res) = @_;

	if ($res->is_success) {
		my $content = $self->json->decode($res->decoded_content);
		return $content;
	}
	
	die $res->decoded_content;
}

1;
