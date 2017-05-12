package Test::Mock::Class::ThrowingTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';
with 'Test::Mock::Class::MockBaseTestRole';

use Test::Assert ':all';

use constant Exception => __PACKAGE__ . '::Exception';
use Exception::Base Exception;

sub test_can_generate_error_from_method_call {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_throw('a_method', 'Ouch!');
    assert_raises( qr/Ouch!/, sub {
        $mock->a_method;
    } );
};

sub test_generates_error_only_when_call_signature_matches {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_throw('a_method', 'Ouch!', args => [3]);
    $mock->a_method(1);
    $mock->a_method(2);
    assert_raises( qr/Ouch!/, sub {
        $mock->a_method(3);
    } );
};

sub test_can_generate_error_on_particular_invocation {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_throw_at(2, 'a_method', 'Ouch!');
    $mock->a_method;
    $mock->a_method;
    assert_raises( qr/Ouch!/, sub {
        $mock->a_method;
    } );
};

sub test_can_generate_exception_object {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->mock_throw('a_method', Exception->new( message => 'Ouch!') );
    assert_raises( qr/Ouch!/, sub {
        $mock->a_method;
    } );
    assert_raises( [Exception], sub {
        $mock->a_method;
    } );
};

1;
