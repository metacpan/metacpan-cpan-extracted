use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::AttributeAssignments;
    use Validation::Class;
    has 'awesome';
    package main;

    my $class = "TestClass::AttributeAssignments";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";
    ok $self->can('awesome'), "$class has an attribute named awesome";
    ok ! defined $self->awesome, "awesome attribute has yet to be defined";
    ok $class eq ref $self->awesome("sweet dee"), "awesome attribute assignment was successful";
    ok "sweet dee" eq $self->awesome, "awesome attribute is holding sweet dee";

    $self  = $class->new(awesome => "sweet dee");

    ok $class eq ref $self, "$class instantiated w/attribute constructor args";
    ok defined $self->awesome, "awesome attribute has yet to be defined";
    ok "sweet dee" eq $self->awesome, "awesome attribute is holding sweet dee";

}

done_testing;
