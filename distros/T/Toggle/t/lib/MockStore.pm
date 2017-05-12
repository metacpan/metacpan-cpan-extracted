package MockStore;

use strict;
use warnings;

sub new {
    my $class = shift;

    bless {}, $class;
}

sub get {
    my ( $self, $key ) = @_;

    return $self->{$key};
}

sub set {
    my ( $self, $key, $value ) = @_;

    $self->{$key} = $value;
}

sub del {
    my ( $self, $key ) = @_;

    delete $self->{$key};
}

1;
