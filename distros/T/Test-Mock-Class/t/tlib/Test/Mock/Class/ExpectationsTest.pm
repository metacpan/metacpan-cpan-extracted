package Test::Mock::Class::ExpectationsTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';
with 'Test::Mock::Class::MockBaseTestRole';

use Test::Assert ':all';

sub test_setting_expectation_on_non_method_throws_error {
    my ($self) = @_;
    my $mock = $self->mock;
    assert_raises( qr/Cannot set expected arguments as no method/, sub {
        $mock->mock_expect_maximum_call_count('a_mising_error', 2);
    } );
};

sub test_max_calls_detects_overrun {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_maximum_call_count('a_method', 2);
    $mock->a_method;
    $mock->a_method;
    assert_raises( qr/Maximum call count/, sub {
        $mock->a_method;
    } );
};

sub test_tally_on_max_calls_sends_pass_on_underrun {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_maximum_call_count('a_method', 2);
    $mock->a_method;
    $mock->a_method;
    $mock->mock_tally;
};

sub test_expect_never_detects_overrun {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_never('a_method');
    assert_raises( qr/Maximum call count/, sub {
        $mock->a_method;
    } );
};

sub test_tally_on_expect_never_still_sends_pass_on_underrun {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_never('a_method');
    $mock->mock_tally;
};

sub test_min_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_minimum_call_count('a_method', 2);
    $mock->a_method;
    $mock->a_method;
    $mock->mock_tally;
};

sub test_failed_never {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_never('a_method');
    assert_raises( qr/Maximum call count/, sub {
        $mock->a_method;
    } );
};

sub test_under_once {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_once('a_method');
    assert_raises( qr/Expected call count/, sub {
        $mock->mock_tally;
    } );
};

sub test_over_once {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_once('a_method');
    $mock->a_method;
    assert_raises( qr/Expected call count/, sub {
        $mock->a_method;
    } );
};

sub test_under_at_least_once {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_at_least_once('a_method');
    assert_raises( qr/Minimum call count/, sub {
        $mock->mock_tally;
    } );
};

sub test_zero_arguments {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => []);
    $mock->a_method;
    $mock->mock_tally;
};

sub test_expected_arguments {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => [1, 2, 3]);
    $mock->a_method(1, 2, 3);
    $mock->mock_tally;
};

sub test_failed_arguments {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => ['this']);
    assert_raises( { -isa => 'Exception::Assertion', reason => qr/Expected/ }, sub {
        $mock->a_method('that');
    } );
};

sub test_failed_arguments_with_two_calls {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => ['this']);
    $mock->a_method('this');
    assert_raises( { -isa => 'Exception::Assertion', reason => qr/Expected/ }, sub {
        $mock->a_method('that');
    } );
};

sub test_wildcards_are_translated_to_anything_expectations {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect('a_method', args => [qr//, 123, qr//]);
    $mock->a_method(100, 123, 101);
    $mock->mock_tally;
};

sub test_specific_passing_sequence {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_expect_at(1, 'a_method', args => [1, 2, 3]);
    $mock->mock_expect_at(2, 'a_method', args => ['Hello']);
    $mock->a_method;
    $mock->a_method(1, 2, 3);
    $mock->a_method('Hello');
    $mock->a_method;
    $mock->mock_tally;
};

1;
