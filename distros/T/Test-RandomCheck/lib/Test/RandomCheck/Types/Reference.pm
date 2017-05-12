package Test::RandomCheck::Types::Reference;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Class::Accessor::Lite (ro => [qw(type)]);
use Test::RandomCheck::Types::List;

sub arbitrary {
    my $self = shift;
    $self->type->arbitrary->map(sub { [@_] });
}

sub memoize_key {
    my ($self, $array_ref) = @_;
    $self->type->memoize_key(@$array_ref);
}

1;
