package WWW::Deezer::SearchResult;

our $VERSION = '0.01';

use Moose;

use WWW::Deezer::Track;

has 'data' => (is => 'ro');
has 'total' => (is => 'ro', isa => 'Int');
has 'request' => (is => 'ro');
has 'index' => (is => 'rw', isa => 'Int');
has 'cursor' => (is => 'rw', isa => 'Int', default => 0);
has 'deezer_obj' => (is => 'rw', isa => 'Ref');

sub count {
    my $self = shift;
    return scalar @{$self->data};
}

sub first {
    my $self = shift;
    
    $self->_return_by_index(0);
}

sub next {
    my $self = shift;
    my $cursor = $self->cursor;
    $self->cursor($cursor+1);

    return $self->_return_by_index($cursor);
}

sub _return_by_index {
    my ($self, $cursor) = @_;

    return undef unless $self->data->[$cursor];

    my $track = WWW::Deezer::Track->new($self->data->[$cursor]);
        $track->deezer_obj($self->deezer_obj);
        $track->set_artist($self->data->[$cursor]->{artist});
        $track->set_album($self->data->[$cursor]->{album});

    return $track;
}

1;
