package Test::Mock::Class::ReturnTest;

use Moose;
extends 'Test::Unit::TestCase';
with 'Test::Mock::Class::MockTestRole';

use Test::Assert ':all';

sub test_default_return {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return('a_method', 'aaa');
    assert_equals('aaa', $mock->a_method);
    assert_equals('aaa', $mock->a_method);
};

sub test_parametered_return {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return('a_method', 'aaa', args => [1, 2, 3]);
    assert_null($mock->a_method);
    assert_equals('aaa', $mock->a_method(1, 2, 3));
};

sub test_set_return_gives_object_reference {
    my ($self) = @_;
    my $mock = $self->mock;
    my $object = Test::Mock::Class::Test::Dummy->new;
    $mock->mock_return('a_method', $object, args => [1, 2, 3]);
    assert_equals($object, $mock->a_method(1, 2, 3));
};

sub test_return_value_can_be_chosen_just_by_pattern_matching_arguments {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return('a_method', 'aaa', args => [qr/hello/i]);
    assert_equals('aaa', $mock->a_method('Hello'));
    assert_null($mock->a_method('Goodbye'));
};

sub test_multiple_methods {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return('a_method', 100, args => [1]);
    $mock->mock_return('a_method', 200, args => [2]);
    $mock->mock_return('another_method', 10, args => [1]);
    $mock->mock_return('another_method', 20, args => [2]);
    assert_equals(100, $mock->a_method(1));
    assert_equals(10, $mock->another_method(1));
    assert_equals(200, $mock->a_method(2));
    assert_equals(20, $mock->another_method(2));
};

sub test_return_sequence {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return_at(0, 'a_method', 'aaa');
    $mock->mock_return_at(1, 'a_method', 'bbb');
    $mock->mock_return_at(3, 'a_method', 'ddd');
    assert_equals('aaa', $mock->a_method);
    assert_equals('bbb', $mock->a_method);
    assert_null($mock->a_method);
    assert_equals('ddd', $mock->a_method);
};

sub test_complicated_return_sequence {
    my ($self) = @_;
    my $mock = $self->mock;
    my $object = Test::Mock::Class::Test::Dummy->new;
    $mock->mock_return_at(1, 'a_method', 'aaa', args => ['a']);
    $mock->mock_return_at(1, 'a_method', 'bbb');
    $mock->mock_return_at(2, 'a_method', $object, args => [qr//, 2]);
    $mock->mock_return_at(2, 'a_method', "value", args => [qr//, 3]);
    $mock->mock_return('a_method', 3, args => [3]);
    assert_null($mock->a_method);
    assert_equals('aaa', $mock->a_method('a'));
    assert_equals($object, $mock->a_method(1, 2));
    assert_equals(3, $mock->a_method(3));
    assert_null($mock->a_method);
};

sub test_multiple_method_sequences {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return_at(0, 'a_method', 'aaa');
    $mock->mock_return_at(1, 'a_method', 'bbb');
    $mock->mock_return_at(0, 'another_method', 'ccc');
    $mock->mock_return_at(1, 'another_method', 'ddd');
    assert_equals('aaa', $mock->a_method);
    assert_equals('ccc', $mock->another_method);
    assert_equals('bbb', $mock->a_method);
    assert_equals('ddd', $mock->another_method);
};

sub test_sequence_fallback {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return_at(0, 'a_method', 'aaa', args => ['a']);
    $mock->mock_return_at(1, 'a_method', 'bbb', args => ['a']);
    $mock->mock_return('a_method', 'AAA');
    assert_equals('aaa', $mock->a_method('a'));
    assert_equals('AAA', $mock->a_method('b'));
};

sub test_method_interference {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return_at(0, 'another_method', 'aaa');
    $mock->mock_return('a_method', 'AAA');
    assert_equals('AAA', $mock->a_method);
    assert_equals('aaa', $mock->another_method);
};

sub test_coderef {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_return('a_method', sub { @_ });
    assert_deep_equals(['a_method', 0, 42], [$mock->a_method(42)]);
};

1;
