package Test::Mock::Class::ExpectationsThatPassTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';
with 'Test::Mock::Class::MockTestRole';

use Test::Assert ':all';

sub test_any_argument {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => [qr//]);
    $mock->a_method(1);
    $mock->a_method('hello');
};

sub test_any_two_arguments {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => [qr//, qr//]);
    $mock->a_method(1, 2);
};

sub test_specific_argument {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => [1]);
    $mock->a_method(1);
};

sub test_arguments_in_sequence {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_at(0, 'a_method', args => [1, 2]);
    $mock->mock_expect_at(1, 'a_method', args => [3, 4]);
    $mock->a_method(1, 2);
    $mock->a_method(3, 4);
};

sub test_at_least_once_satisfied_by_one_call {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_at_least_once('a_method');
    $mock->a_method;
};

sub test_at_least_once_satisfied_by_two_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_at_least_once('a_method');
    $mock->a_method;
    $mock->a_method;
};

sub test_once_satisfied_by_one_call {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_once('a_method');
    $mock->a_method;
};

sub test_minimum_calls_satisfied_by_enough_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_minimum_call_count('a_method', 1);
    $mock->a_method;
};

sub test_minimum_calls_satisfied_by_too_many_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_minimum_call_count('a_method', 3);
    $mock->a_method;
    $mock->a_method;
    $mock->a_method;
    $mock->a_method;
};

sub test_maximum_calls_satisfied_by_enough_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_maximum_call_count('a_method', 1);
    $mock->a_method;
};

sub test_maximum_calls_satisfied_by_no_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_maximum_call_count('a_method', 1);
};

sub test_once_with_args {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_once('a_method', args => [1, 2, 3]);
    $mock->a_method(1, 2, 3);
};

sub test_count_without_args_and_once_with_args {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_once('a_method', args => [1, 2, 3]);
    $mock->mock_expect_call_count('a_method', 2);
    $mock->a_method(1, 2, 3);
    $mock->a_method;
};

1;
