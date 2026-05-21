use warnings;
use strict;

use Test::More;
use Test::Warnings;
use Test::MockModule;

use lib "t/lib";

# Test package
package Stacked; ## no critic (Modules::RequireFilenameMatchesPackage)
our $VERSION = 1;
sub foo { 'original_foo' }
sub bar { 'original_bar' }
package main; ## no critic (Modules::RequireFilenameMatchesPackage)

# Basic: new() returns distinct objects
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    isnt($m1, $m2, 'new() returns distinct objects for same package');
    is($m1->get_package, 'Stacked', '... both target the same package');
    is($m2->get_package, 'Stacked', '... both target the same package');
}

# Independent mocking: different subs on different objects
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'mock1_foo' });
    is(Stacked::foo(), 'mock1_foo', 'first object mocks foo');
    is(Stacked::bar(), 'original_bar', 'bar is untouched');

    {
        my $m2 = Test::MockModule->new('Stacked', distinct => 1);
        $m2->mock('bar', sub { 'mock2_bar' });
        is(Stacked::foo(), 'mock1_foo', 'foo still mocked by first object');
        is(Stacked::bar(), 'mock2_bar', 'bar mocked by second object');
    }

    is(Stacked::foo(), 'mock1_foo', 'foo still mocked after second object destroyed');
    is(Stacked::bar(), 'original_bar', 'bar restored after second object destroyed');
}

is(Stacked::foo(), 'original_foo', 'foo restored after first object destroyed');

# Stacked mocking: same sub, LIFO destruction order
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'layer1' });
    is(Stacked::foo(), 'layer1', 'first layer');

    {
        my $m2 = Test::MockModule->new('Stacked', distinct => 1);
        $m2->mock('foo', sub { 'layer2' });
        is(Stacked::foo(), 'layer2', 'second layer overrides first');
    }

    is(Stacked::foo(), 'layer1', 'first layer restored after second destroyed');
}

is(Stacked::foo(), 'original_foo', 'original restored after all objects destroyed');

# Stacked mocking: same sub, non-LIFO destruction order (inner destroyed last)
{
    my $m2;
    {
        my $m1 = Test::MockModule->new('Stacked', distinct => 1);
        $m1->mock('foo', sub { 'layer1' });

        $m2 = Test::MockModule->new('Stacked', distinct => 1);
        $m2->mock('foo', sub { 'layer2' });
        is(Stacked::foo(), 'layer2', 'layer2 active');
    }

    # m1 destroyed, but m2 (on top) is still alive
    is(Stacked::foo(), 'layer2', 'layer2 still active after layer1 object destroyed');

    undef $m2;
    is(Stacked::foo(), 'original_foo', 'original restored after both destroyed (non-LIFO)');
}

# Three layers
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'L1' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'L2' });

    my $m3 = Test::MockModule->new('Stacked', distinct => 1);
    $m3->mock('foo', sub { 'L3' });

    is(Stacked::foo(), 'L3', 'three layers: top wins');

    # Destroy middle
    undef $m2;
    is(Stacked::foo(), 'L3', 'destroying middle does not affect top');

    # Destroy top
    undef $m3;
    is(Stacked::foo(), 'L1', 'after top and middle gone, first layer restored');

    # Destroy bottom
    undef $m1;
    is(Stacked::foo(), 'original_foo', 'all gone, original restored');
}

# Explicit unmock interacts correctly with stack
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'A' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'B' });

    is(Stacked::foo(), 'B', 'B is active');

    $m2->unmock('foo');
    is(Stacked::foo(), 'A', 'after unmocking B, A is restored');

    $m1->unmock('foo');
    is(Stacked::foo(), 'original_foo', 'after unmocking A, original restored');
}

# is_mocked is per-object
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'x' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);

    ok($m1->is_mocked('foo'), 'm1 reports foo as mocked');
    ok(!$m2->is_mocked('foo'), 'm2 does not report foo as mocked');

    $m2->mock('bar', sub { 'y' });
    ok(!$m1->is_mocked('bar'), 'm1 does not report bar as mocked');
    ok($m2->is_mocked('bar'), 'm2 reports bar as mocked');
}

# original() returns the correct original per object
{
    my $orig_foo = \&Stacked::foo;
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'first' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'second' });

    is($m1->original('foo'), $orig_foo, 'm1 original is the true original');
    # m2 saved m1s mock as its "original"
    is($m2->original('foo')->(), 'first', 'm2 original is m1 mock');
}

# Re-mock by a non-top object: when the top unmocks, the non-top object's
# most recent install should be active, not its initial install.
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'm1_v1' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'm2' });
    is(Stacked::foo(), 'm2', 're-mock setup: m2 active');

    # m1 (non-top) re-mocks foo with a new value.
    $m1->mock('foo', sub { 'm1_v2' });
    is(Stacked::foo(), 'm1_v2', 'non-top re-mock takes effect immediately');

    # m2 unmocks. Stack should restore m1's CURRENT install (m1_v2),
    # not m1's initial install (m1_v1).
    $m2->unmock('foo');
    is(Stacked::foo(), 'm1_v2', 'top unmock restores non-top objects current install, not initial');

    $m1->unmock('foo');
    is(Stacked::foo(), 'original_foo', 'all unmocked: original restored');
}

# Re-mock by top object also stays consistent
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'a' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'b1' });
    $m2->mock('foo', sub { 'b2' });
    is(Stacked::foo(), 'b2', 'top re-mock active');

    $m2->unmock('foo');
    is(Stacked::foo(), 'a', 'top unmock falls back to non-top install');
}

# Mid-stack unmock after a non-top re-mock must NOT leave the unmocked
# layer's clobbered coderef installed at the symbol. The non-top re-mock
# overwrote *Pkg::sub with the layer's installed coderef (per the documented
# "most recent mock wins" contract), so when that layer is removed the
# symbol must be restored to the layer that's still on top.
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'A' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'B' });

    # Non-top re-mock by m1 clobbers the symbol to C.
    $m1->mock('foo', sub { 'C' });
    is(Stacked::foo(), 'C', 'non-top re-mock clobbers symbol (documented)');

    # m1 unmocks while m2 is still on top. Symbol must reflect m2's mock
    # (the layer that should still be active), not m1's stale install.
    $m1->unmock('foo');
    is(Stacked::foo(), 'B',
        'mid-stack unmock after non-top re-mock restores top layer');

    $m2->unmock('foo');
    is(Stacked::foo(), 'original_foo', 'all unmocked: original restored');
}

# Same shape as above but via the destructor path.
{
    my $m2;
    {
        my $m1 = Test::MockModule->new('Stacked', distinct => 1);
        $m1->mock('foo', sub { 'A' });

        $m2 = Test::MockModule->new('Stacked', distinct => 1);
        $m2->mock('foo', sub { 'B' });

        $m1->mock('foo', sub { 'C' });          # non-top re-mock
        is(Stacked::foo(), 'C', 'destructor path: clobber visible');

        # m1 destructed here as scope exits.
    }
    is(Stacked::foo(), 'B',
        'mid-stack DESTROY after non-top re-mock restores top layer');

    undef $m2;
    is(Stacked::foo(), 'original_foo', 'destructor path: cleanup ok');
}

# Three-layer middle-layer re-mock then middle-layer unmock: top layer
# must be re-installed; the bottom layer remains untouched and is restored
# correctly when the top eventually unmocks.
{
    my $m1 = Test::MockModule->new('Stacked', distinct => 1);
    $m1->mock('foo', sub { 'L1' });

    my $m2 = Test::MockModule->new('Stacked', distinct => 1);
    $m2->mock('foo', sub { 'L2' });

    my $m3 = Test::MockModule->new('Stacked', distinct => 1);
    $m3->mock('foo', sub { 'L3' });

    $m2->mock('foo', sub { 'L2_new' });        # middle re-mock; clobbers symbol
    is(Stacked::foo(), 'L2_new', 'middle re-mock clobbers symbol');

    $m2->unmock('foo');
    is(Stacked::foo(), 'L3',
        'mid-stack unmock with non-empty layer above restores top (L3)');

    $m3->unmock('foo');
    is(Stacked::foo(), 'L1', 'after L3 gone: L1 still active');

    $m1->unmock('foo');
    is(Stacked::foo(), 'original_foo', 'three-layer cleanup');
}

# GH #64 contract under stacking: define() then a non-top re-mock by the
# defining object must still restore the originally-defined sub when all
# layers have been unmocked. Without the fix, the GH #64 path captures
# \&{$sub_name} -- which is another object's installed coderef when we are
# not at top of stack -- and unmock leaves THAT sibling coderef installed
# instead of the defined sub.
{
    package Stacked64; ## no critic (Modules::RequireFilenameMatchesPackage)
    our $VERSION = 1;
    package main;
    ok(!defined &Stacked64::wrapper, 'Stacked64::wrapper does not exist initially');

    my $m1 = Test::MockModule->new('Stacked64', no_auto => 1, distinct => 1);
    $m1->define('wrapper', sub { 'defined_value' });

    my $m2 = Test::MockModule->new('Stacked64', no_auto => 1, distinct => 1);
    $m2->mock('wrapper', sub { 'sibling_value' });

    # m1 (non-top) redefines its own defined sub. Per the documented
    # "most recent mock wins" contract, the symbol now holds m1's new
    # coderef. The internal _orig bookkeeping must capture m1's PRIOR
    # install ('defined_value'), not the symbol's current value
    # ('sibling_value').
    $m1->mock('wrapper', sub { 'redefined_value' });
    is(Stacked64::wrapper(), 'redefined_value', 'GH #64 + stacking: m1 redef visible');

    $m2->unmock('wrapper');
    is(Stacked64::wrapper(), 'redefined_value',
        'GH #64 + stacking: m1 redef stays visible after m2 unmocks');

    $m1->unmock('wrapper');
    is(Stacked64::wrapper(), 'defined_value',
        'GH #64 + stacking: unmock restores the defined sub, not a siblings coderef');
}

done_testing;
