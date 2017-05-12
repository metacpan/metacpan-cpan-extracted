package Text::Mecabist::Iter;
use strict;
use warnings;
use Moo::Role;

has index => (is => 'rw', default => 0);
has skip  => (is => 'rw', default => 0);
has last  => (is => 'rw', default => 0);

my $doc;
sub doc {
    my $self = shift;
    $doc = shift if @_;
    $doc;
}

sub has_next {
    my $self = shift;
    $self->index < $self->doc->count - 1;
}

sub has_prev {
    my $self = shift;
    $self->index > 0;
}

sub next {
    my $self = shift;
    $self->has_next && $self->doc->nodes->[$self->index + 1];
}

sub prev {
    my $self = shift;
    $self->has_prev && $self->doc->nodes->[$self->index - 1];
}

1;
