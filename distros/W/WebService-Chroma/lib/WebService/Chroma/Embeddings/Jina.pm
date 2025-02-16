package WebService::Chroma::Embeddings::Jina;

use Moo;
use WebService::Jina;

has api_key => (
	is => 'rw',
	required => 1,
	lazy => 1,
);

has model => (
	is => 'rw',
	default => sub { 'jina-clip-v2' }
);

sub ai {
	return $_[0]->{ai} ||= WebService::Jina->new(
		api_key => $_[0]->api_key
	);
}

sub get {
        my ($self, $data) = @_;

        my $res = $self->ai->embedding(
                model => $self->model,
                input => [ { text => $data } ]
        );

        my $embedding = $res->{data}->[0]->{embedding};

        if ($embedding && scalar @{$embedding}) {
                return $embedding;
        }

        die 'error retrieving embeddings';
}

1;
