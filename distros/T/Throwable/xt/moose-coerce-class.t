#!perl
use strict;
use warnings;
use Test::More;

{
    package MyClass;
    use Moose;
    with 'StackTrace::Auto';
}

ok(my $obj = eval { MyClass->new }, "Create Moose object")
    or diag $@;

isa_ok($obj, "MyClass");
isa_ok($obj->stack_trace, "Devel::StackTrace", 'The trace');

done_testing();
