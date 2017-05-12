use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::Test1::RoleRequirements::Role::A;
    use Validation::Class;
    has 'foobar';

}

{

    package TestClass::Test1::RoleRequirements::Role::B;
    use Validation::Class;
    has 'foobar';
    has 'barbaz';

}

{

    package TestClass::Test1::Define;
    use Validation::Class;
    set role => 'TestClass::Test1::RoleRequirements::Role::A';
    set role => 'TestClass::Test1::RoleRequirements::Role::B';
    package TestClass::Test1::Consume;
    use Validation::Class;
    set role => 'TestClass::Test1::Define';
    package main;
    my $class = "TestClass::Test1::Consume";
    my $self  = $class->new;
    ok $class eq ref $self, "$class instantiated";
    ok $self->proto->can('does'), "$class prototype has does method";
    ok $self->proto->does('TestClass::Test1::Define'), "$class prototype has role TestClass::Test1::Define";
    ok $self->proto->does('TestClass::Test1::RoleRequirements::Role::A'), "$class prototype has role TestClass::Test1::RoleRequirements::Role::A";
    ok $self->proto->does('TestClass::Test1::RoleRequirements::Role::B'), "$class prototype has role TestClass::Test1::RoleRequirements::Role::B";

}

done_testing;
