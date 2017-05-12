package WWW::Docker::Http;
use Moose::Role;
use LWP::UserAgent;
use WWW::Docker::List;

has 'address' => (
	default => sub {$ENV{DOCKER_HOST} or '/var/run/docker.sock'},
	is      => 'rw',
	isa     => 'Str',
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

has 'uri' => (
	default => sub {URI->new()},
	is      => 'ro',
	isa     => 'URI',
	lazy    => 1,
);

1;
