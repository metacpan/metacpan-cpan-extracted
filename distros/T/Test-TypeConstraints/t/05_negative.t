#!/usr/bin/perl

use strict;
use warnings;

use Test::TypeConstraints;
use Test::More;

note "Some roles and classes for testing"; {
    {
        package Some::Role;
        use Mouse::Role;
    }

    {
        package Some::Class;
        use Mouse;
        with "Some::Role";
    }

    {
        package Other::Role;
        use Mouse::Role;
    }

    {
        package Other::Class;
        use Mouse;
        with 'Other::Role';
    }
}

subtest "type_isnt" => sub {
    my $obj = Some::Class->new;
    type_isa  $obj, "Some::Class";
    type_isnt $obj, "Other::Class";
};

subtest "type_doesnt" => sub {
    my $obj = Some::Class->new;
    type_does   $obj, "Some::Role";
    type_doesnt $obj, "Other::Role";    
};


done_testing;
