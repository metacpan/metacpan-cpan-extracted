#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 84;

UR::Object::Type->define(
    class_name => 'URT::Parent',
    has => [
        name => { is => 'String', default_value => 'Anonymous' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Child',
    is => 'URT::Parent',
    has => [
        color => { is => 'String', default_value => 'clear' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::GrandChild',
    is => 'URT::Child',
    has => [
        name => { is => 'String', default_value => 'Doe' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::SingleChild',
    is => ['UR::Singleton', 'URT::Child'],
);

UR::Object::Type->define(
    class_name =>'URT::BoolThing',
    has => [
        boolval => { is => 'Boolean', default_value => 1 },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::IntThing',
    has => [
        intval => { is => 'Integer', default_value => 100 },
    ],
);

# Make a pair of classes we'll use to test setting indirect properties at 
# creation time.  The ObjThing has an int_value, through a bridge, to an IntThing's intval
UR::Object::Type->define(
    class_name => 'URT::BridgeThing',
    has => [
        int_thing => { is => 'URT::IntThing', id_by => 'int_thing_id' },
        int_value => { via => 'int_thing', to => 'intval' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::ObjThing',
    has => [
        bridge_thing => { is => 'URT::BridgeThing', id_by => 'bridge_thing_id' },
        int_value => { via => 'bridge_thing', to => 'int_value', default_value => 1234 },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::CommandThing',
    is => 'Command',
    has => [
        opt => { is => 'Boolean', default_value => 1 },
    ],
);


my $p = URT::Parent->create(id => 1);
ok($p, 'Created a parent object without name');
is($p->name, 'Anonymous', 'object has default value for name');
is($p->name('Bob'), 'Bob', 'We can set the name');
is($p->name, 'Bob', 'And it returns the correct name after setting it');

$p = URT::Parent->create(id => 100, name => undef);
ok($p, 'Created a parent object with the empty string for the name');
is($p->name, undef, 'Name is correctly empty');
is($p->name('Joe'), 'Joe', 'We can set it to something else');
is($p->name, 'Joe', 'And it returns the correct name after setting it');


my $o = URT::BoolThing->create(id => 1);
ok($o, 'Created a BoolThing without a value');
is($o->boolval, 1, 'it has the default value for boolval');
is($o->boolval(0), 0, 'we can set the value');
is($o->boolval, 0, 'And it returns the correct value after setting it');

$o = URT::BoolThing->create(id => 2, boolval => 0);
ok($o, 'Created a BoolThing with the value 0');
is($o->boolval, 0, 'it has the right value for boolval');
is($o->boolval(1), 1, 'we can set the value');
is($o->boolval, 1, 'And it returns the correct value after setting it');

$o = URT::IntThing->create(id => 1);
ok($o, 'Created an IntThing without a value');
is($o->intval, 100, 'it has the default value for intval');
is($o->intval(1), 1, 'we can set the value');
is($o->intval, 1, 'And it returns the correct value after setting it');


$o = URT::IntThing->create(id => 2, intval => 0);
ok($o, 'Created an IntThing with the value 0');
is($o->intval, 0, 'it has the right value for boolval');
is($o->intval(1), 1, 'we can set the value');
is($o->intval, 1, 'And it returns the correct value after setting it');


$o = URT::ObjThing->create(id => 1);
ok($o, 'Created an ObjThing without an int_value');
is($o->int_value, 1234, 'It has the default value for int_value');
ok($o->bridge_thing_id, 'The ObjThing has a bridge_thing_id');
ok($o->bridge_thing, 'We can get its bridge_thing object');
is($o->bridge_thing->id, $o->bridge_thing_id, 'The IDs match for bridge_thing_id and URT::BridgeThing ID param');
$o = $o->bridge_thing;
is($o->int_value, 1234, 'The BridgeThing has the correct value for int_value');
ok($o->int_thing, 'We can get its int_thing object');
is($o->int_thing->id, $o->int_thing_id, "The IDs match for the hangoff object");
is($o->int_thing->intval, 1234, "The int_thing's intval is 1234");


$o = URT::ObjThing->create(id => 2, int_value => 9876);
ok($o, 'Created ObjThing with int_value 9876');
is($o->int_value, 9876, 'It has the correct value for int_value');
ok($o->bridge_thing_id, 'The ObjThing has a bridge_thing_id');
ok($o->bridge_thing, 'We can get its bridge_thing object');
is($o->bridge_thing->id, $o->bridge_thing_id, 'The IDs match for bridge_thing_id and URT::BridgeThing ID param');
$o = $o->bridge_thing;
is($o->int_value, 9876, 'The BridgeThing has the correct value for int_value');
ok($o->int_thing_id, 'The BridgeThing has an int_thing_id value');
ok($o->int_thing, 'We can get its int_thing object');
is($o->int_thing->id, $o->int_thing_id, "The IDs match for the hangoff object");
is($o->int_thing->intval, 9876, "The int_thing's intval is 9876");



my $int_thing = URT::IntThing->get(intval => 1234);
ok($int_thing, 'Got the IntThing with intval 1234, again');
$o = URT::ObjThing->create(id => 3);
ok($o, 'Created another ObjThing without an int_value');
is($o->int_value, 1234, "The ObjThing's int_value is the default 1234");
ok($o->bridge_thing, "This ObjThing's bridge_thing property has a value");
is($o->bridge_thing->int_thing_id, $int_thing->id, 'The bridge_thing points to the original IntThing having the value 1234');


$p = URT::Parent->create(id => 2, name => 'Fred');
ok($p, 'Created a parent object with a name');
is($p->name, 'Fred', 'Returns the correct name');



my $c = URT::Child->create();
ok($c, 'Created a child object without name or color');
is($c->name, 'Anonymous', 'child has the default value for name');
is($c->color, 'clear', 'child has the default value for color');
is($c->name('Joe'), 'Joe', 'we can set the value for name');
is($c->name, 'Joe', 'And it returns the correct name after setting it');
is($c->color, 'clear', 'color still returns the default value');

$c = URT::GrandChild->create();
ok($c, 'Created a grandchild object without name or color');
is($c->name, 'Doe', 'child has the default value for name');
is($c->color, 'clear', 'child has the default value for color');
is($c->name('Joe'), 'Joe', 'we can set the value for name');
is($c->name, 'Joe', 'And it returns the correct name after setting it');
is($c->color, 'clear', 'color still returns the default value');

$c = URT::SingleChild->_singleton_object;
ok($c, 'Got an object for the child singleton class');
is($c->name, 'Anonymous','name has the default value');
is($c->name('Mike'), 'Mike', 'we can set the name');
is($c->name, 'Mike', 'And it returns the correct name after setting it');
is($c->color, 'clear', 'color still returns the default value');


my $cmd = URT::CommandThing->create();
ok($cmd, 'Got a CommandThing object without specifying --opt');
is($cmd->opt, 1, '--opt value is 1');

$cmd = URT::CommandThing->create(opt => 0);
ok($cmd, 'Created CommandThing with --opt 0');
is($cmd->opt, 0, '--opt value is 0');

# test oo defaults

my $p1 = URT::Parent->get(1);
my $p2 = URT::Parent->get(2);

class URT::Thing2a {
    has => [
        o1 => { is => 'URT::Parent', default_value => 2 },
    ]
};
class URT::Thing2b {
    has => [
        o1 => { is => 'URT::Parent', id_by => 'o1_id', default_value => 2 },
    ]
};
class URT::Thing2c {
    has => [
        o1 => { is => 'URT::Parent', is_many => 1, default_value => [1,2] },
    ]
};


note("test default values specified as IDs");

my $t1 = URT::Thing2a->create();
is($t1->o1, $p2, "default value is set (no id_by): $p2");

my $t2 = URT::Thing2b->create();
is($t1->o1, $p2, "default value is set (with id_by) $p2");

my $t3 = URT::Thing2c->create();
my @t3o1 = $t3->o1;
is("@t3o1", "$p1 $p2", "default value is set to two items on an is_many property");


note("test default values overridden in construction not doing anything");

my $t4 = URT::Thing2a->create(o1 => $p1);
is($t4->o1, $p1, "value is set as specified to $p1 not the default $p2");

my $t5 = URT::Thing2b->create(o1 => $p1);
is($t5->o1, $p1, "value is set as specified to $p1 not the default $p2 (id_by)");

$DB::single = 1;
my $t6 = URT::Thing2c->create(o1 => [$p2]);
my @t6o1 = $t6->o1;
is("@t6o1", "$p2", "value is set to as specified $p2 no the default of $p1 and $p2 (is_many)");


note("test default values specified as queries");

class URT::Thing3a {
    has => [
        o1 => { is => 'URT::Parent', default_value => { name => "Fred" } },
    ]
};
class URT::Thing3b {
    has => [
        o1 => { is => 'URT::Parent', id_by => 'o1_id', default_value => { name => "Fred" } },
    ]
};
class URT::Thing3c {
    has => [
        o1 => { is => 'URT::Parent', is_many => 1, default_value => { name => ["Fred","Bob"] } },
    ]
};

my $t7 = URT::Thing3a->create();
is($t7->o1, $p2, "default value is $p2 as specified by query");

my $t2q = URT::Thing3b->create();
is($t7->o1, $p2, "default value is $p2 as specified by query");

my $t9 = URT::Thing3c->create();
my @t9o1 = $t9->o1;
is("@t9o1", "$p1 $p2", "default value is set to both $p1 and $p2 as specified by query");

SKIP: {
    skip "UR::Command::sub_command_dirs() complains if there's no module, even if the class exists", 4;

    my($cmd_class,$params) = URT::CommandThing->resolve_class_and_params_for_argv('--opt');
    is($cmd_class, 'URT::CommandThing', 'resolved the correct command class');
    is($params->{'opt'}, 1, 'Specifying --opt on the command line sets opt param to 1');

    ($cmd_class,$params) = URT::CommandThing->resolve_class_and_params_for_argv();
    is($params->{'opt'}, 1, 'opt option has the default value with no argv arguments');

    ($cmd_class,$params) = URT::CommandThing->resolve_class_and_params_for_argv('--noopt');
    is($params->{'opt'}, 0, 'Specifying --noopt sets opt params to 0');
}
