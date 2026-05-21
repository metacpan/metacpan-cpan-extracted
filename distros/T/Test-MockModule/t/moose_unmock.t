use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moose; 1 } or plan skip_all => "Moose not installed";
}

use Test::MockModule;

# Local-orig case: parent has its own foo
{
    package Issue55::UnmockLocalOrig; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub foo { 'orig' }
}

# Inherited case: child has no local foo; inherits from parent
{
    package Issue55::UnmockParent; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub bar { 'parent_bar' }
}
{
    package Issue55::UnmockInherited; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    extends 'Issue55::UnmockParent';
}

# Local-orig: mock+unmock restores method on meta and direct call
{
    my $mock = Test::MockModule->new('Issue55::UnmockLocalOrig');
    $mock->mock( foo => sub { 'mocked' } );
    is(Issue55::UnmockLocalOrig->foo, 'mocked', "local-orig: mock visible");
    ok(Issue55::UnmockLocalOrig->meta->get_method('foo'),
        "local-orig: meta has foo while mocked");

    $mock->unmock('foo');
    is(Issue55::UnmockLocalOrig->foo, 'orig', "local-orig: original restored");
    ok(Issue55::UnmockLocalOrig->meta->get_method('foo'),
        "local-orig: meta still has foo after unmock");
}

# Re-mock: mocking the same name twice must not lose the *true* original.
# The second mock should replace the first mock body, but unmock should still
# restore the pre-any-mock implementation -- not the first mock body.
{
    package Issue55::UnmockReMock; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub foo { 'orig' }
}
{
    my $mock = Test::MockModule->new('Issue55::UnmockReMock');
    $mock->mock( foo => sub { 'first_mock' } );
    is(Issue55::UnmockReMock->foo, 'first_mock', "re-mock: first mock active");

    $mock->mock( foo => sub { 'second_mock' } );
    is(Issue55::UnmockReMock->foo, 'second_mock', "re-mock: second mock replaces first");

    $mock->unmock('foo');
    is(Issue55::UnmockReMock->foo, 'orig',
        "re-mock+unmock restores the true original, not the first mock");
    ok(Issue55::UnmockReMock->meta->get_method('foo'),
        "re-mock+unmock leaves meta with original method");
}

# Inherited-orig: mock adds method, unmock should remove it from child meta
# so the inheritance lookup falls back to parent.
{
    my $mock = Test::MockModule->new('Issue55::UnmockInherited');
    $mock->mock( bar => sub { 'mocked_bar' } );
    is(Issue55::UnmockInherited->bar, 'mocked_bar', "inherited-orig: mock visible");
    ok(Issue55::UnmockInherited->meta->get_method('bar'),
        "inherited-orig: meta has bar while mocked");

    $mock->unmock('bar');
    is(Issue55::UnmockInherited->bar, 'parent_bar',
        "inherited-orig: parent method takes over after unmock");
    ok(!Issue55::UnmockInherited->meta->get_method('bar'),
        "inherited-orig: child meta no longer has bar after unmock");
}

done_testing;
