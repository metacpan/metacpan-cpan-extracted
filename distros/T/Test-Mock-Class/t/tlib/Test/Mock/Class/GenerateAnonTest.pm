package Test::Mock::Class::GenerateAnonTest;

use Test::Unit::Lite;

use Moose;
extends 'Test::Unit::TestCase';
with 'Test::Mock::Class::MockTestRole';

use Test::Assert ':all';

sub test_mock_anon_class {
    my ($self) = @_;
    my $mock = $self->mock;
    assert_true($mock->can('a_method'));
    assert_null($mock->a_method);
};

sub test_mock_add_method {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->meta->add_mock_method('extra_method');
    assert_true($mock->can('extra_method'));
    assert_null($mock->extra_method);
};

sub test_mock_add_constructor {
    my ($self) = @_;
    my $mock = $self->mock;
    $mock->meta->add_mock_constructor('extra_new');
    assert_true($mock->can('extra_new'));

    my $mock2 = $mock->extra_new;
    assert_true($mock2->can('extra_new'));
};

1;
