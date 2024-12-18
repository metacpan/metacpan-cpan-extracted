package WebService::Chroma::Embeddings::Ollama;

use Moo;
use LWP::UserAgent;
use JSON;

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

has base_url => (
	is => 'rw',
	default => 'http://localhost:11434'
);

has model => (
	is => 'rw',
	default => sub { 'nomic-embed-text' }
);

sub get {
        my ($self, $data) = @_;

	my $url = URI->new($self->base_url . '/api/embeddings');

	my $res = $self->ua->post(
		$url,
		content => $self->json->encode({
			model => $self->model,
			prompt => $data
		})
	);

	if ($res->is_success) {
		my $embedding = $self->json->decode($res->decoded_content)->{embedding};

		if ($embedding && scalar @{$embedding}) {
			return $embedding;
		}
	}

        die 'error retrieving embeddings';
}

1;
