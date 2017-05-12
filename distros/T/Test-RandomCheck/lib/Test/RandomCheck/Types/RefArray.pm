package Test::RandomCheck::Types::ArrayRef;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Class::Accessor::Lite (ro => [qw(min max type)], rw => ['_inner_type']);
use Test::RandomCheck::Types::List;
use Test::RandomCheck::Types::Reference;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $list_type = list ($self->type, $self->min, $self->max);
    $self->_inner_type(Test::RandomCheck::Types::Reference->new(
        type => $list_type
    ));
    $self;
}

sub arbitrary {
    my $self = shift;
    $self->_inner_type->arbitrary;
}

sub memoize_key {
    my $self = shift;
    $self->_inner_type->memoize_key(@_);
}

1;
