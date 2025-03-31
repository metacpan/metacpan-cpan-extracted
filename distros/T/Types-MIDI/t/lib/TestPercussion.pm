package TestPercussion;

use Moo;
use Types::MIDI '+PercussionNote';

has percussion => (
    is      => 'rw',
    isa     => PercussionNote,
    coerce  => 1,
    default => 'Acoustic Snare',
);

sub hit {
    my $self = shift;
    return $self->percussion;
}

1;
