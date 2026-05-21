use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Mouse; 1 } or plan skip_all => "Mouse not installed";
}

use Test::MockModule;

# Mouse counterpart of t/moose_multi.t. Same scenarios, validating that
# the per-sub layer stack treats Mouse::Meta::Class consistently with
# Class::MOP::Class.

{
    package MouseMulti::Local; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    sub greet { 'orig_greet' }
    sub other { 'orig_other' }
}

# LIFO unmock
{
    my $m1 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'A' });
    is(MouseMulti::Local->greet, 'A', 'LIFO: m1 mock active');

    my $m2 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m2->mock('greet', sub { 'B' });
    is(MouseMulti::Local->greet, 'B', 'LIFO: m2 mock takes over');

    $m2->unmock('greet');
    is(MouseMulti::Local->greet, 'A', 'LIFO: m1 mock restored after m2 unmocks');

    $m1->unmock('greet');
    is(MouseMulti::Local->greet, 'orig_greet',
        'LIFO: original restored after m1 unmocks');
    ok(MouseMulti::Local->meta->get_method('greet'),
        'LIFO: meta has greet again after full teardown');
}

# Non-LIFO unmock (the case the singleton previously hid)
{
    my $m1 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'A' });

    my $m2 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m2->mock('greet', sub { 'B' });
    is(MouseMulti::Local->greet, 'B', 'non-LIFO: m2 active');

    $m1->unmock('greet');
    is(MouseMulti::Local->greet, 'B',
        'non-LIFO: m2 still mocking after m1 unmocks');

    $m2->unmock('greet');
    is(MouseMulti::Local->greet, 'orig_greet',
        'non-LIFO: original restored after m2 unmocks');
}

# Non-top re-mock + mid-stack unmock
{
    my $m1 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'A' });

    my $m2 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m2->mock('greet', sub { 'B' });

    $m1->mock('greet', sub { 'C' });
    is(MouseMulti::Local->greet, 'C',
        'non-top re-mock takes effect via meta');

    $m1->unmock('greet');
    is(MouseMulti::Local->greet, 'B',
        'mid-stack unmock after non-top re-mock hands meta back to top');

    $m2->unmock('greet');
    is(MouseMulti::Local->greet, 'orig_greet',
        'non-top re-mock cleanup: original restored');
}

# Destructor path on Mouse
{
    my $m2;
    {
        my $m1 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
        $m1->mock('greet', sub { 'A' });

        $m2 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
        $m2->mock('greet', sub { 'B' });
        # m1 destructed here.
    }
    is(MouseMulti::Local->greet, 'B',
        'destructor: mid-stack DESTROY leaves top in control of meta');
    undef $m2;
    is(MouseMulti::Local->greet, 'orig_greet',
        'destructor: cleanup ok');
}

# Independent methods
{
    my $m1 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m1->mock('greet', sub { 'AA' });

    my $m2 = Test::MockModule->new('MouseMulti::Local', distinct => 1);
    $m2->mock('other', sub { 'BB' });

    is(MouseMulti::Local->greet, 'AA', 'independent: greet from m1');
    is(MouseMulti::Local->other, 'BB', 'independent: other from m2');

    $m1->unmock('greet');
    is(MouseMulti::Local->greet, 'orig_greet',
        'independent: greet restored when m1 unmocks');
    is(MouseMulti::Local->other, 'BB',
        'independent: other untouched when m1 unmocks');

    $m2->unmock('other');
    is(MouseMulti::Local->other, 'orig_other',
        'independent: other restored when m2 unmocks');
}

# Inherited method, two mock objects
{
    package MouseMulti::Parent; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    sub bar { 'parent_bar' }
}
{
    package MouseMulti::Child; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    extends 'MouseMulti::Parent';
}

{
    my $m1 = Test::MockModule->new('MouseMulti::Child', distinct => 1);
    $m1->mock('bar', sub { 'child_A' });

    my $m2 = Test::MockModule->new('MouseMulti::Child', distinct => 1);
    $m2->mock('bar', sub { 'child_B' });
    is(MouseMulti::Child->bar, 'child_B', 'inherited: m2 mock visible');

    $m1->unmock('bar');
    is(MouseMulti::Child->bar, 'child_B',
        'inherited: m2 mock still visible after m1 unmocks');

    $m2->unmock('bar');
    is(MouseMulti::Child->bar, 'parent_bar',
        'inherited: parent method restored after both unmock');
    ok(!MouseMulti::Child->meta->get_method('bar'),
        'inherited: child meta entry removed after full teardown');
}

# Edge case: immutable -> mutable transition between two mock objects.
# Mouse counterpart of the toggle test in t/moose_multi.t.
{
    package MouseMulti::Toggle; ## no critic (Modules::RequireFilenameMatchesPackage)
    use Mouse;
    sub greet { 'orig_greet' }
    __PACKAGE__->meta->make_immutable;
}

{
    my $m1 = Test::MockModule->new('MouseMulti::Toggle', distinct => 1);
    {
        local $SIG{__WARN__} = sub {};   # swallow the immutable carp
        $m1->mock('greet', sub { 'A' });
    }
    is(MouseMulti::Toggle->greet, 'A', 'toggle: m1 mock active (symbol-only)');

    MouseMulti::Toggle->meta->make_mutable;

    my $m2 = Test::MockModule->new('MouseMulti::Toggle', distinct => 1);
    $m2->mock('greet', sub { 'B' });
    is(MouseMulti::Toggle->greet, 'B', 'toggle: m2 mock active (meta path)');

    $m1->unmock('greet');
    is(MouseMulti::Toggle->greet, 'B',
        'toggle: m2 mock still active after mid-stack m1 unmock');

    $m2->unmock('greet');
    is(MouseMulti::Toggle->greet, 'orig_greet',
        'toggle: original restored after full teardown');
    ok(MouseMulti::Toggle->meta->get_method('greet'),
        'toggle: meta has greet again after full teardown');
}

done_testing;
