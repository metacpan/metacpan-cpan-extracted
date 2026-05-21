use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Moose; 1 } or plan skip_all => "Moose not installed";
}

use Test::MockModule;

# Two mock objects on the same Moose method must coexist correctly: each
# mocks independently, layering is LIFO, non-LIFO destruction is safe, and
# tearing down one layer must not leak a sibling layer's saved state into
# the meta-class.

{
    package MooseMulti::Local; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub greet { 'orig_greet' }
    sub other { 'orig_other' }
}

# LIFO unmock: top layer pops first, then bottom layer pops.
{
    my $m1 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'A' });
    is(MooseMulti::Local->greet, 'A', 'LIFO: m1 mock active');

    my $m2 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m2->mock('greet', sub { 'B' });
    is(MooseMulti::Local->greet, 'B', 'LIFO: m2 mock takes over');

    $m2->unmock('greet');
    is(MooseMulti::Local->greet, 'A', 'LIFO: m1 mock restored after m2 unmocks');

    $m1->unmock('greet');
    is(MooseMulti::Local->greet, 'orig_greet',
        'LIFO: original restored after m1 unmocks');
    ok(MooseMulti::Local->meta->get_method('greet'),
        'LIFO: meta has greet again after full teardown');
}

# Non-LIFO unmock: bottom layer pops first, then top layer pops. The
# pre-PR singleton implementation hid this case; the new design must keep
# m2's mock active after m1 unmocks, and restore the original after both.
{
    my $m1 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'A' });

    my $m2 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m2->mock('greet', sub { 'B' });
    is(MooseMulti::Local->greet, 'B', 'non-LIFO: m2 active');

    $m1->unmock('greet');
    is(MooseMulti::Local->greet, 'B',
        'non-LIFO: m2 still mocking after m1 (mid-stack) unmocks');

    $m2->unmock('greet');
    is(MooseMulti::Local->greet, 'orig_greet',
        'non-LIFO: original restored after m2 unmocks');
}

# Non-top re-mock under Moose: when a non-top object re-mocks, its newest
# install must take effect immediately (per the documented contract), and
# subsequent mid-stack unmock must hand control back to the still-living
# top layer rather than leaving the stale install in the meta.
{
    my $m1 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'A' });

    my $m2 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m2->mock('greet', sub { 'B' });

    $m1->mock('greet', sub { 'C' });
    is(MooseMulti::Local->greet, 'C',
        'non-top re-mock takes effect via meta');

    $m1->unmock('greet');
    is(MooseMulti::Local->greet, 'B',
        'mid-stack unmock after non-top re-mock hands meta back to top');

    $m2->unmock('greet');
    is(MooseMulti::Local->greet, 'orig_greet',
        'non-top re-mock cleanup: original restored');
}

# Destructor path on Moose: ensure DESTROY-driven mid-stack unmock leaves
# the surviving top layer in control of meta.
{
    my $m2;
    {
        my $m1 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
        $m1->mock('greet', sub { 'A' });

        $m2 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
        $m2->mock('greet', sub { 'B' });
        # m1 destructed here.
    }
    is(MooseMulti::Local->greet, 'B',
        'destructor: mid-stack DESTROY leaves top in control of meta');
    undef $m2;
    is(MooseMulti::Local->greet, 'orig_greet',
        'destructor: cleanup ok');
}

# Independent mocks on different methods: m1 mocks one method, m2 mocks a
# different method. Each unmock must only affect its own method.
{
    my $m1 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'AA' });

    my $m2 = Test::MockModule->new('MooseMulti::Local', distinct => 1);
    $m2->mock('other', sub { 'BB' });

    is(MooseMulti::Local->greet, 'AA', 'independent: greet from m1');
    is(MooseMulti::Local->other, 'BB', 'independent: other from m2');

    $m1->unmock('greet');
    is(MooseMulti::Local->greet, 'orig_greet',
        'independent: greet restored when m1 unmocks');
    is(MooseMulti::Local->other, 'BB',
        'independent: other untouched when m1 unmocks');

    $m2->unmock('other');
    is(MooseMulti::Local->other, 'orig_other',
        'independent: other restored when m2 unmocks');
}

# Inherited method, two mock objects: child has no local foo; both objects
# mock it; after full teardown, the local meta entry must be gone so
# inheritance lookup falls back to the parent.
{
    package MooseMulti::Parent; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub bar { 'parent_bar' }
}
{
    package MooseMulti::Child; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    extends 'MooseMulti::Parent';
}

{
    my $m1 = Test::MockModule->new('MooseMulti::Child', distinct => 1);
    $m1->mock('bar', sub { 'child_A' });

    my $m2 = Test::MockModule->new('MooseMulti::Child', distinct => 1);
    $m2->mock('bar', sub { 'child_B' });
    is(MooseMulti::Child->bar, 'child_B', 'inherited: m2 mock visible');

    $m1->unmock('bar');
    is(MooseMulti::Child->bar, 'child_B',
        'inherited: m2 mock still visible after m1 (mid-stack) unmocks');

    $m2->unmock('bar');
    is(MooseMulti::Child->bar, 'parent_bar',
        'inherited: parent method restored after both unmock');
    ok(!MooseMulti::Child->meta->get_method('bar'),
        'inherited: child meta entry removed after full teardown');
}

# Edge case: immutable -> mutable transition between two mock objects.
# m1 mocks while the class is immutable (symbol-table-only path), then the
# user makes the class mutable, then m2 mocks via the meta path. On
# mid-stack unmock of m1, the popped layer's meta_orig (undef, since m1
# was symbol-only) must NOT clobber m2's captured meta_orig. Otherwise
# the eventual top-of-stack restore removes the method instead of
# restoring the original.
{
    package MooseMulti::Toggle; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Moose;
    sub greet { 'orig_greet' }
    __PACKAGE__->meta->make_immutable;
}

{
    my $m1 = Test::MockModule->new('MooseMulti::Toggle', distinct => 1);
    {
        local $SIG{__WARN__} = sub {};   # swallow the immutable carp
        $m1->mock('greet', sub { 'A' });
    }
    is(MooseMulti::Toggle->greet, 'A', 'toggle: m1 mock active (symbol-only)');

    MooseMulti::Toggle->meta->make_mutable;

    my $m2 = Test::MockModule->new('MooseMulti::Toggle', distinct => 1);
    $m2->mock('greet', sub { 'B' });
    is(MooseMulti::Toggle->greet, 'B', 'toggle: m2 mock active (meta path)');

    $m1->unmock('greet');
    is(MooseMulti::Toggle->greet, 'B',
        'toggle: m2 mock still active after mid-stack m1 unmock');

    $m2->unmock('greet');
    is(MooseMulti::Toggle->greet, 'orig_greet',
        'toggle: original restored after full teardown');
    ok(MooseMulti::Toggle->meta->get_method('greet'),
        'toggle: meta has greet again after full teardown');
}

done_testing;
