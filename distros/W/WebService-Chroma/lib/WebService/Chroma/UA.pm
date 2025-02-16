package WebService::Chroma::UA;

use Moo;
use LWP::UserAgent;
use JSON;
use Module::Load;

has base_url => (
	is => 'ro',
);

has embeddings_model => (
	is => 'rw',
	trigger => sub {
		if ($_[1] && $_[0]->embeddings) {
			$_[0]->embeddings->model($_[1]);
		}
	}
);

has embeddings_api_key => (
	is => 'rw',
	lazy => 1,
	trigger => sub {
		if ($_[1] && $_[0]->embeddings) {
			$_[0]->embeddings->api_key($_[1]);
		}
	}
);

has embeddings_base_url => (
	is => 'rw',
	trigger => sub {
		if ($_[1] && $_[0]->embeddings) {
			$_[0]->embeddings->base_url($_[1]);
		}
	}
);

has embeddings_class => (
	is => 'ro',
	trigger => sub {
		return unless $_[1];
		my $class = 'WebService::Chroma::Embeddings::' . $_[1];
		load $class;
		$_[0]->embeddings(
			$class->new(
				($_[0]->embeddings_model ? (model => $_[0]->embeddings_model) : ()),
				($_[0]->embeddings_api_key ? (api_key => $_[0]->embeddings_api_key) : ()),
			)
		);
	}
);

has embeddings => (
	is => 'rw',
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
