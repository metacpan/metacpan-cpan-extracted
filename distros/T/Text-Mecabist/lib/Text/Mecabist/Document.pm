package Text::Mecabist::Document;
use strict;
use warnings;

use overload (
    q{""} => 'stringify',
    fallback => 1,
);

use Moo;

has count => (
    is => 'rw',
    default => 0,
);

has nodes => (
    is => 'ro',
    default => sub { [ ] },
);

sub add {
    my ($self, $node) = @_;
    $node->doc($self);
    $node->index($self->count);
    $self->count(push @{ $self->nodes }, $node);
}

sub each {
    my ($self, $cb) = @_;
    for my $node (@{ $self->nodes }) {
        next if $node->skip;
        $cb->($node); 
        last if $node->last;
    }
}

sub stringify {
    my ($self) = @_;
    $self->join('text');
}

sub join {
    my ($self, $key) = @_;
    
    my @r;
    for my $node (@{ $self->nodes }) {
        next if $node->skip;
        push @r, $node->$key // "";
        last if $node->last;
    }

    join "", @r;
}

1;
