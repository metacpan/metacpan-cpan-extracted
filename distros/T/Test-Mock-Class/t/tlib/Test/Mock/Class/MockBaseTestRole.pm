package Test::Mock::Class::MockBaseTestRole;

use Moose::Role;

use Test::Assert ':all';

use Test::Mock::Class;

has metamock => (
    is      => 'rw',
    isa     => 'Test::Mock::Class',
    clearer => 'clear_metamock'
);

has mock => (
    is      => 'rw',
    does    => 'Test::Mock::Class::Role::Object',
    clearer => 'clear_mock'
);

around set_up => sub {
    my ($next, $self) = @_;
    my $metamock = $self->metamock(
        Test::Mock::Class->create_mock_anon_class(
            class => 'Test::Mock::Class::Test::Dummy',
        )
    );
    assert_true($metamock->isa('Moose::Meta::Class'));
    my $mock = $self->mock($metamock->new_object);
    assert_true($mock->does('Test::Mock::Class::Role::Object'));
    return $self->$next();
};

around tear_down => sub {
    my ($next, $self) = @_;
    $self->clear_mock;
    $self->clear_metamock;
    return $self->$next();
};

1;
