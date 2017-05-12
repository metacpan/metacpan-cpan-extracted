package Test::RandomCheck::Types::String;
use strict;
use warnings;
use parent "Test::RandomCheck::Types";
use Class::Accessor::Lite (ro => [qw(min max)], rw => ['_list_type']);
use Test::RandomCheck::Types::List qw(list);
use Test::RandomCheck::Types::Char qw(char);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_list_type(list (char, $self->min, $self->max));
    $self;
}

sub arbitrary {
    my $self = shift;
    $self->_list_type->arbitrary->map(sub {join '', @_});
}

sub memoize_key {
    my ($self, $str) = @_;
    $self->_list_type->memoize_key(split //, $str);
}

1;
