use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moose; 1 }           or plan skip_all => "Moose not installed";
    eval { require Test::Exception; 1 } or plan skip_all => "Test::Exception not installed";
}

use Test::Exception;
use Test::MockModule;

# Local method on a Moose class
{
    package Issue55::RedefineLocal; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub foo { 'real_foo' }
}

# Inherited method (child has no local foo)
{
    package Issue55::RedefineParent; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub bar { 'parent_bar' }
}
{
    package Issue55::RedefineChild; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    extends 'Issue55::RedefineParent';
}

# Empty class for define() coverage
{
    package Issue55::DefineTarget; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
}

# redefine() on a locally-defined Moose method goes through the meta path
{
    my $mock = Test::MockModule->new('Issue55::RedefineLocal');
    $mock->redefine( foo => sub { 'redefined' } );
    is(Issue55::RedefineLocal->foo, 'redefined', "redefine() mocks Moose method");
    ok(Issue55::RedefineLocal->meta->get_method('foo'),
        "redefine() registered foo on the meta-class");

    $mock->unmock('foo');
    is(Issue55::RedefineLocal->foo, 'real_foo', "redefine()+unmock restores original");
}

# redefine() on a method that doesn't exist anywhere should die
{
    my $mock = Test::MockModule->new('Issue55::RedefineLocal');
    throws_ok {
        $mock->redefine( missing_method => sub { 'no' } );
    } qr/missing_method/, "redefine() dies when method doesn't exist";
}

# redefine() on an inherited method should succeed (parent provides it)
{
    my $mock = Test::MockModule->new('Issue55::RedefineChild');
    lives_ok {
        $mock->redefine( bar => sub { 'mocked_bar' } );
    } "redefine() on inherited method does not die";
    is(Issue55::RedefineChild->bar, 'mocked_bar', "inherited method redefined");
    ok(Issue55::RedefineChild->meta->get_method('bar'),
        "redefine() on inherited method registered on child meta");

    $mock->unmock('bar');
    is(Issue55::RedefineChild->bar, 'parent_bar',
        "redefine()+unmock falls back to parent");
    ok(!Issue55::RedefineChild->meta->get_method('bar'),
        "child meta no longer has bar after unmock");
}

# define() on a Moose class for a method that does not exist
{
    my $mock = Test::MockModule->new('Issue55::DefineTarget');
    $mock->define( newly_defined => sub { 'fresh' } );
    is(Issue55::DefineTarget->newly_defined, 'fresh',
        "define() installs new method on Moose class");
    ok(Issue55::DefineTarget->meta->get_method('newly_defined'),
        "define() registered the new method on the meta-class");

    $mock->unmock('newly_defined');
    ok(!Issue55::DefineTarget->can('newly_defined'),
        "define()+unmock removes the method entirely");
    ok(!Issue55::DefineTarget->meta->get_method('newly_defined'),
        "define()+unmock removes from meta-class too");
}

# define() should die if the method already exists
{
    my $mock = Test::MockModule->new('Issue55::RedefineLocal');
    throws_ok {
        $mock->define( foo => sub { 'no' } );
    } qr/foo/, "define() dies when method already exists";
}

done_testing;
