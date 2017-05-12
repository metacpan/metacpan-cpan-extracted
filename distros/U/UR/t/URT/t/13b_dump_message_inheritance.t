BEGIN {
    # This environment variable overrides default UR behavior so unsetting it
    # for the test.
    delete $ENV{UR_COMMAND_DUMP_DEBUG_MESSAGES};
};

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

use Test::More;

plan tests => 142;

ok(UR::Object::Type->define( class_name => 'A'), 'Define class A');
ok(UR::Object::Type->define( class_name => 'B'), 'Define class B');

my $a = A->create(id => 1);
ok($a, 'Create object a');

my $b = B->create(id => 1);
ok($b, 'Create object b');

# Make sure each instance can control its own messaging flags
is($a->dump_debug_messages(0), 0, 'Set dump_debug_messages on a to 0');
is($a->dump_debug_messages(), 0, 'dump_debug_messages on a is still 0');

is($b->dump_debug_messages(1), 1, 'Set dump_debug_messages on b to 1');
is($b->dump_debug_messages(), 1, 'dump_debug_messages on b is still 1');

is($a->dump_debug_messages(), 0, 'dump_debug_messages on a is still 0');
is($b->dump_debug_messages(), 1, 'dump_debug_messages on b is still 1');

# Make sure classes inherit their messaging behavior from parents if they don't
# otherwise change it
ok(UR::Object::Type->define( class_name => 'Parent'), 'Define class Parent');
ok(UR::Object::Type->define( class_name => 'ChildA', is => 'Parent'), 'Define class ChildA');
ok(UR::Object::Type->define( class_name => 'ChildB', is => 'Parent'), 'Define class ChildB');

$a = ChildA->create();
ok($a, 'Create object a');
$b = ChildB->create();
ok($b, 'Create object b');

is(Parent->dump_debug_messages(), undef, 'Parent dump_debug_messages() starts off as undef');
is(Parent->dump_debug_messages(0), 0, 'Setting Parent dump_debug_messages() to 0');
is(ChildA->dump_debug_messages(), 0, 'ChildA dump_debug_messages() is 0');
is($a->dump_debug_messages(), 0, 'object a dump_debug_messages() is 0');
is(ChildB->dump_debug_messages(), 0, 'ChildB dump_debug_messages() is 0');
is($b->dump_debug_messages(), 0, 'object b dump_debug_messages() is 0');

# Change the parent and the child classes and instances inherit it, since they haven't
# overriden anything yet
foreach my $val ( 1, 0 ) {
    is(Parent->dump_debug_messages($val), $val, "Change Parent dump_debug_messages() to $val");
    is(Parent->dump_debug_messages(), $val, 'Parent dump_debug_messages() is set');
    is(ChildA->dump_debug_messages(), $val, 'ChildA dump_debug_messages() matches Parent');
    is($a->dump_debug_messages(), $val, 'object a dump_debug_messages() matches Parent');
    is(ChildB->dump_debug_messages(), $val, 'ChildB dump_debug_messages() matches Parent');
    is($b->dump_debug_messages(), $val, 'object b dump_debug_messages() matches Parent');
}

# Twiddle both the parent and one of the child classes
foreach my $parent_val ( 2, 1, 0) {
    is(Parent->dump_debug_messages($parent_val), $parent_val, "Set Parent dump_debug_messages() to $parent_val");
    foreach my $child_val ( 1, 0 ) {
        is(ChildA->dump_debug_messages($child_val), $child_val, "Change ChildA dump_debug_messages() to $child_val");
        is(ChildA->dump_debug_messages(), $child_val, 'ChildA dump_debug_messages() is set');
        is($a->dump_debug_messages(), $child_val, 'object a dump_debug_messages() matches ChildA');

        is(Parent->dump_debug_messages(), $parent_val, 'Parent dump_debug_messages() is still set');
        is(ChildB->dump_debug_messages(), $parent_val, 'ChildB dump_debug_messages() matches Parent');
        is($b->dump_debug_messages(), $parent_val, 'object b dump_debug_messages() matches Parent');
    }
}
    
my $a2 = ChildA->create();
my $b2 = ChildB->create();

# Explicity set all the invilved entities
is(Parent->dump_debug_messages(1), 1, ' Set Parent dump_debug_messages() to 1');
is(ChildA->dump_debug_messages(2), 2, ' Set ChildA dump_debug_messages() to 2');
is(ChildB->dump_debug_messages(3), 3, ' Set Parent dump_debug_messages() to 3');
is($a->dump_debug_messages(4), 4, ' Set object a dump_debug_messages() to 4');
is($a2->dump_debug_messages(5), 5, ' Set object a2 dump_debug_messages() to 5');
is($b->dump_debug_messages(6), 6, ' Set object b dump_debug_messages() to 6');
is($b2->dump_debug_messages(7), 7, ' Set object b dump_debug_messages() to 7');

# Check the values
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 2, 'ChildA dump_debug_messages() is 2');
is(ChildB->dump_debug_messages(), 3, 'Parent dump_debug_messages() is 3');
is($a->dump_debug_messages(), 4, 'object a dump_debug_messages() is 4');
is($a2->dump_debug_messages(), 5, 'object a2 dump_debug_messages() is 5');
is($b->dump_debug_messages(), 6, 'object b dump_debug_messages() is 6');
is($b2->dump_debug_messages(), 7, 'object b dump_debug_messages() is 7');

# Now, start setting some of them to undef, meaning they should again inherit from their parent
#diag('Clear setting on object a');
$a->dump_debug_messages(undef);
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 2, 'ChildA dump_debug_messages() is 2');
is(ChildB->dump_debug_messages(), 3, 'Parent dump_debug_messages() is 3');
is($a->dump_debug_messages(), 2, 'object a dump_debug_messages() is now 2');
is($a2->dump_debug_messages(), 5, 'object a2 dump_debug_messages() is 5');
is($b->dump_debug_messages(), 6, 'object b dump_debug_messages() is 6');
is($b2->dump_debug_messages(), 7, 'object b dump_debug_messages() is 7');

#diag('Clear setting on ChildA');
ChildA->dump_debug_messages(undef);
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 1, 'ChildA dump_debug_messages() is 1');
is(ChildB->dump_debug_messages(), 3, 'Parent dump_debug_messages() is 3');
is($a->dump_debug_messages(), 1, 'object a dump_debug_messages() is now 1');
is($a2->dump_debug_messages(), 5, 'object a2 dump_debug_messages() is 5');
is($b->dump_debug_messages(), 6, 'object b dump_debug_messages() is 6');
is($b2->dump_debug_messages(), 7, 'object b dump_debug_messages() is 7');

#diag('Clear setting on object a2');
$a2->dump_debug_messages(undef);
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 1, 'ChildA dump_debug_messages() is 1');
is(ChildB->dump_debug_messages(), 3, 'Parent dump_debug_messages() is 3');
is($a->dump_debug_messages(), 1, 'object a dump_debug_messages() is now 1');
is($a2->dump_debug_messages(), 1, 'object a2 dump_debug_messages() is 1');
is($b->dump_debug_messages(), 6, 'object b dump_debug_messages() is 6');
is($b2->dump_debug_messages(), 7, 'object b dump_debug_messages() is 7');

#diag('Clear setting on object b');
$b->dump_debug_messages(undef);
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 1, 'ChildA dump_debug_messages() is 1');
is(ChildB->dump_debug_messages(), 3, 'Parent dump_debug_messages() is 3');
is($a->dump_debug_messages(), 1, 'object a dump_debug_messages() is now 1');
is($a2->dump_debug_messages(), 1, 'object a2 dump_debug_messages() is 1');
is($b->dump_debug_messages(), 3, 'object b dump_debug_messages() is 3');
is($b2->dump_debug_messages(), 7, 'object b dump_debug_messages() is 7');

#diag('Clear setting on ChildB');
ChildB->dump_debug_messages(undef);
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 1, 'ChildA dump_debug_messages() is 1');
is(ChildB->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is($a->dump_debug_messages(), 1, 'object a dump_debug_messages() is now 1');
is($a2->dump_debug_messages(), 1, 'object a2 dump_debug_messages() is 1');
is($b->dump_debug_messages(), 1, 'object b dump_debug_messages() is 1');
is($b2->dump_debug_messages(), 7, 'object b dump_debug_messages() is 7');

#diag('Clear setting on object b2');
$b2->dump_debug_messages(undef);
is(Parent->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is(ChildA->dump_debug_messages(), 1, 'ChildA dump_debug_messages() is 1');
is(ChildB->dump_debug_messages(), 1, 'Parent dump_debug_messages() is 1');
is($a->dump_debug_messages(), 1, 'object a dump_debug_messages() is now 1');
is($a2->dump_debug_messages(), 1, 'object a2 dump_debug_messages() is 1');
is($b->dump_debug_messages(), 1, 'object b dump_debug_messages() is 1');
is($b2->dump_debug_messages(), 1, 'object b dump_debug_messages() is 1');

my @ENV_VARS = ('UR_DUMP_DEBUG_MESSAGES', 'UR_COMMAND_DUMP_DEBUG_MESSAGES');
$DB::single=1;
foreach $var ( @ENV_VARS ) {
    delete $ENV{$_} foreach @ENV_VARS;  # clear them first

    #diag("use the $var env var");
    $ENV{$var} = 99;

    is(Parent->dump_debug_messages(), 99, 'Parent dump_debug_messages() is 1');
    is(ChildA->dump_debug_messages(), 99, 'ChildA dump_debug_messages() is 1');
    is(ChildB->dump_debug_messages(), 99, 'Parent dump_debug_messages() is 1');
    is($a->dump_debug_messages(), 99, 'object a dump_debug_messages() is now 1');
    is($a2->dump_debug_messages(), 99, 'object a2 dump_debug_messages() is 1');
    is($b->dump_debug_messages(), 99, 'object b dump_debug_messages() is 1');
    is($b2->dump_debug_messages(), 99, 'object b dump_debug_messages() is 1');
}

