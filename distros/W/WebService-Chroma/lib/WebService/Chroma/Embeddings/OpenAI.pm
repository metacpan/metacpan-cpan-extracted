package WebService::Chroma::Embeddings::OpenAI;

use Moo;
use OpenAI::API;

has ai => (
        is => 'ro',
        default => sub {
                OpenAI::API->new();
        }
);

has model => (
	is => 'rw',
	default => sub { 'text-embedding-3-large' }
);

sub get {
        my ($self, $data) = @_;

        my $res = $self->ai->embeddings(
                model => $self->model,
                input => $data
        );

        my $embedding = $res->{data}->[0]->{embedding};

        if ($embedding && scalar @{$embedding}) {
                return $embedding;
        }

        die 'error retrieving embeddings';
}

1;
