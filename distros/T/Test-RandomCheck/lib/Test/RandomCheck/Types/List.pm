package Test::RandomCheck::Types::List;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Class::Accessor::Lite (ro => [qw(min max type)]);
use Exporter qw(import);
use Test::RandomCheck::ProbMonad;

our @EXPORT = qw(list);

sub list ($;$$) {
    my $type = shift;
    my ($min, $max) = @_;
    $min //= 0;
    $max //= 9;
    Test::RandomCheck::Types::List->new(
        type => $type, min => $min, max => $max
    );
}

sub arbitrary {
    my $self = shift;
    my ($min, $max) = ($self->min, $self->max);
    my $generator = $self->type->arbitrary;
    gen {
        my ($rand, $size) = @_;
        my $width = int (($max - $min) * $size / 100);
        $rand->next_int($min, $min + $width);
    }->flat_map(sub {
        my $n = shift;
        gen {
            my ($rand, $size) = @_;
            map { $generator->pick($rand, $size) } 1 .. $n;
        };
    });
}

sub memoize_key {
    my ($self, @xs) = @_;
    join '\0', map { $self->type->memoize_key($_) } @xs;
}

1;
