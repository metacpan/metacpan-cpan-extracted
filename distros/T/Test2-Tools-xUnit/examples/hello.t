package Hello;

use Test2::Tools::xUnit;
use Test2::V0;
use Moo;

my $package_variable;

sub startup : BeforeAll {
    my $class = shift;

    $package_variable = 42;
}

sub shutdown : AfterAll {
    undef $package_variable;
}

sub setup : BeforeEach {
    my $self = shift;

    $self->{true} ||= 1;
    $self->{false} = 0;
}

sub teardown : AfterEach {}

sub check_instance_variable : Test {
    my $self = shift;

    ok $package_variable, 'pass';
    is $self->{true}, 1, 'pass again';
}

sub mutate_instance_variable : Test {
    my $self = shift;

    $self->{true}++;

    is $self->{true}, 2;
}

sub hello_again_world_skip_with_reason : Test {
    my $self = shift;

    ok $self->{true}, 'pass';
    ok $self->{true}, 'pass again';
}

sub hello_again_world_todo : Test Todo(Not done yet) {
    my $self = shift;

    ok $self->{false}, 'fail';
    ok $self->{true},  'unexpected pass';
}

done_testing;
