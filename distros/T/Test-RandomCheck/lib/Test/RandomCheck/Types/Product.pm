package Test::RandomCheck::Types::Product;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Class::Accessor::Lite (ro => [qw(types)]);
use Exporter qw(import);
use Test::RandomCheck::Types::AllInteger;
use Test::RandomCheck::ProbMonad;

our @EXPORT = qw(product);

sub product (@) {
    Test::RandomCheck::Types::Product->new(
        types => [@_]
    );
}

sub arbitrary {
    my $self = shift;
    gen {
        my ($rand, $size) = @_;
        map { $_->arbitrary->pick($rand, $size) } @{$self->types};
    };
}

sub memoize_key {
    my ($self, @xs) = @_;

    my @keys;
    for my $i (1 .. $#{$self->types}) {
        push @keys, $self->types->[$i]->memoize_key($xs[$i]);
    }

    join '\0', @keys;
}

1;
