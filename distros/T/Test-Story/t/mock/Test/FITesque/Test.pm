package Test::FITesque::Test;
use Moose;
use Test::MockBuilder;
has data => (
    isa => 'ArrayRef',
    is  => q{rw},
);
our $ADDED_TESTS = [];
our $TEST_BUILDER = Test::MockBuilder->new();

sub run_tests {
    my $self = shift;
    push @{ $Test::FITesque::ADDED_TESTS }, $self->data;
}

1;
