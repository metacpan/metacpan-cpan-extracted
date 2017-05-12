use Test::More;
use strict;

BEGIN {
    eval("use Moose");
    plan skip_all => "Moose not installed" if $@;
}

package RoleTest;

use Moose::Role;

requires 'some_role';

sub non_role { }

package MooseTest;

use Moose;
has 'someattr' => ( is => 'rw', isa => 'Str', required => 1 );
sub word { }

package TestCases;

use Test::Pockito;
use Test::Pockito::Moose::Role;

use Test::Simple tests => 4;
{

    my $pocket = Test::Pockito->new("Foo");
    my $mock   = $pocket->mock("MooseTest");

    $pocket->when( $mock->word )->then(2);
    $pocket->when( $mock->someattr(1) )->then(2);

    ok( $mock->word == 2,        "Basic subs work" );
    ok( $mock->someattr(1) == 2, "Mocking an attribute works" );

}

{  
    Test::Pockito::Moose::Role::convert('Role','RoleTest');

    my $pocket = Test::Pockito->new("Mock");

    my $mock = $pocket->mock("Role::RoleTest");

    $pocket->when( $mock->some_role(1) )->then(2);
    $pocket->when( $mock->non_role(3) )->then(4);

    ok( $mock->some_role(1) == 2, "Mocking a role works" );
    ok( $mock->non_role(3) == 4,  "Mocking a sub in a role works" );
}

1;

