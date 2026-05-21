use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moose; 1 }            or plan skip_all => "Moose not installed";
    eval { require Moose::Util; 1 }      or plan skip_all => "Moose::Util not installed";
    eval { require Test::Exception; 1 }  or plan skip_all => "Test::Exception not installed";
}

use Test::Exception;
use Test::MockModule;

# Role with a required method
{
    package Issue55::FooRole; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose::Role;
    requires 'foo';
}

# Class implementing the role
{
    package Issue55::FooClass; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub foo { 'real_foo' }
    with 'Issue55::FooRole';
}

# A second role that also requires foo — applied dynamically AFTER the mock,
# which forces Moose to re-check requirements against the (mocked) class meta.
{
    package Issue55::AnotherFooRole; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose::Role;
    requires 'foo';
    sub other { 'other' }
}

my $mock = Test::MockModule->new('Issue55::FooClass');
$mock->mock( foo => sub { 'mocked_foo' } );

is(Issue55::FooClass->new->foo, 'mocked_foo', "mock visible on class");

my $obj = Issue55::FooClass->new;
lives_ok {
    Moose::Util::apply_all_roles($obj, 'Issue55::AnotherFooRole');
} "applying a role that requires the mocked method does not die";

is($obj->foo,   'mocked_foo', "mock still visible after dynamic role application");
is($obj->other, 'other',      "role's own method works after composition");

done_testing;
