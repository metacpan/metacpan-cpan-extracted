package WWW::Docker::Client;
use Moose::Role;
use namespace::autoclean;
use WWW::Docker::Item;
use LWP::UserAgent;
use HTTP::Request;
use JSON;

has 'address' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has 'scheme' => (
	default => 'http',
	is      => 'ro',
	isa     => 'Str', # TODO: validate with enumerator
);

has 'json' => (
	default => sub {JSON->new->utf8()},
	is      => 'ro',
	isa     => 'JSON',
	lazy    => 1,
);

has 'ua' => (
	default => sub {
		my $self = shift;
		if (-S $self->address()) {
			require LWP::Protocol::http::SocketUnixAlt;
			LWP::Protocol::implementor(http => 'LWP::Protocol::http::SocketUnixAlt');
		}
		LWP::UserAgent->new();
	},
	is      => 'ro',
	isa     => 'LWP::UserAgent',
	lazy    => 1,
);

sub get {
	my ($self, $path, %options) = @_;
	my $uri      = $self->uri($path, %options);
	my $response = $self->ua->get($uri);
	return $self->_handle_request($response);
}

sub request {
	my ($self, $request) = @_;
	my $response = $self->ua->request($request);
	return $self->_handle_request($response);
}

sub expand {
	my ($self, $item_class, $item_info) = @_;
	my ($object, @objects);
	$item_class = 'WWW::Docker::Item::' . $item_class;
	if (ref($item_info) eq 'ARRAY') {
		foreach my $item (@$item_info) {
			push(@objects, $item_class->new($item));
		}
		return wantarray ? @objects : \@objects;
	} else {
		return $item_class->new($item_info);
	}
}

sub uri {
	my ($self, $path, %opts) = @_;
	my $uri = URI->new($self->scheme() . ':' . $self->address() . $path);
	$uri->query_form(%opts);
	return $uri;
}

sub _handle_request {
	my ($self, $response) = @_;
	my $response_code     = $response->code();
	unless ($response_code == 200 or $response_code == 201 or $response_code == 204) { # TODO: implement a real http error handler
		die "FAILURE: $response_code - " . $response->content();
	}
	my $content = $response->content();
	my $data    = eval{$self->json->decode($content)};
	die "JSON ERROR: $@" if $@;
	return $data;
}

1;
