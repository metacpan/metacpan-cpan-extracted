package Test::RandomCheck::Types::Enum;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Class::Accessor::Lite (ro => [qw(items)]);
use List::MoreUtils ();
use Test::RandomCheck::ProbMonad;

sub arbitrary {
    my $self = shift;
    elements @{$self->items};
}

sub memoize_key {
    my ($self, $item) = @_;
    my $n = List::MoreUtils::first_index { $_ eq $item } @{$self->items};
    $n;
}

1;
