use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Mouse; 1 }            or plan skip_all => "Mouse not installed";
    eval { require Mouse::Role; 1 }      or plan skip_all => "Mouse::Role not installed";
    eval { require Test::Exception; 1 }  or plan skip_all => "Test::Exception not installed";
}

use Test::Exception;
use Test::MockModule;

{
    package Issue55::MouseRole; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse::Role;
    requires 'foo';
}

{
    package Issue55::MouseClass; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    sub foo { 'real_foo' }
    with 'Issue55::MouseRole';
}

{
    package Issue55::MouseParent; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    sub bar { 'parent_bar' }
}
{
    package Issue55::MouseChild; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    extends 'Issue55::MouseParent';
}

# Basic mock-and-call
my $mock = Test::MockModule->new('Issue55::MouseClass');
$mock->mock( foo => sub { 'mocked_foo' } );
is(Issue55::MouseClass->new->foo, 'mocked_foo', "Mouse mock visible");
ok(Issue55::MouseClass->meta->get_method('foo'),
    "Mouse meta has foo while mocked");

$mock->unmock('foo');
is(Issue55::MouseClass->new->foo, 'real_foo', "Mouse unmock restores original");

# Inherited unmock path
my $imock = Test::MockModule->new('Issue55::MouseChild');
$imock->mock( bar => sub { 'mocked_bar' } );
is(Issue55::MouseChild->bar, 'mocked_bar', "Mouse inherited mock visible");
$imock->unmock('bar');
is(Issue55::MouseChild->bar, 'parent_bar', "Mouse unmock falls through to parent");
ok(!Issue55::MouseChild->meta->get_method('bar'),
    "Mouse child meta no longer has bar after unmock");

done_testing;
