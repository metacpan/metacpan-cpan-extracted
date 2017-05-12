use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

use Data::Dumper;
use Test::More;
plan tests => 84;

UR::Object::Type->define(
    class_name => 'URT::Value1',
    has => [
        p1 => { is => 'Text', is_optional => 1 },
    ]
);

UR::Object::Type->define(
    class_name => 'URT::Value2',
    has => [
        p1 => { is => 'Text', is_optional => 1 },
    ]
);

UR::Object::Type->define(
    class_name => 'URT::Value3',
    has => [
        p1 => { is => 'Text', is_optional => 1 },
    ]
);

UR::Object::Type->define(
    class_name => 'URT::Param',
    id_by => [
        thing_id => { is => 'Number' },
        name => { is => 'String' },
        value_class_name => { is => 'Text' },
        value_id => { is => 'Text' },
    ],
    has => [
        thing => { is => 'URT::Thing', id_by => 'thing_id' },
        value => { is => 'UR::Object', id_class_by => 'value_class_name', id_by => 'value_id' },
    ],
);

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        'thing_id' => { is => 'Number' },
    ],
    has => [
        params => { is => 'URT::Param', reverse_as => 'thing', is_many => 1 },
        param_values => { via => 'params', to => 'value', is_many => 1, is_mutable => 1 }, 
        # Actually, either of these property definitions will work
        interesting_param_values => { via => 'params', to => 'value', is_many => 1, is_mutable => 1,
                                      where => [ name => 'interesting'] },

        #interesting_params => { is => 'URT::Param', reverse_as => 'thing', is_many => 1,
        #                        where => [name => 'interesting']},
        #interesting_param_values => { via => 'interesting_params', to => 'value', is_many => 1, is_mutable => 1 },
        #< Test adding primitives, giving the class name
        friends => {
            via => 'params',
            to => 'value_id',
            is_many => 1,
            is_mutable => 1,
            where => [qw/ name friends value_class_name UR::Value /],
        },
    ],
);

my $v1 = URT::Value1->create(1);
ok($v1, "made a test value 1");

my $v2 = URT::Value2->create(2);
ok($v2, "made a test value 2");

my $v3 = URT::Value3->create(3);
ok($v3, "made a test value 3");

ok("URT::Param"->can("value_id"), "created a property for value_id implicitly");
ok("URT::Param"->can("value_class_name"), "created a property for value_class_name implicitly");

#$DB::single = 1;
#my $o1 = URT::Thing->create(thing_id => 2, param_values => [$v2,$v3]);
my $o1 = URT::Thing->create(thing_id => 1);
ok($o1, "created a test object which has-many of a test property");

#<>#
# test by direct construction of the bridge 
my $p = URT::Param->create(thing_id => 1, name => 'uninteresting', value => $v1); 
ok($p, "made an object with a value as a paramter");
is($p->value_class_name, ref($v1), "class name is set on the new object as expected");
is($p->value_id, $v1->id, "id is set on the new object as expected");
#$DB::single = 1;
is($p->value,$v1,"got the value back");

my @p = $o1->params();
is(scalar(@p),1,"got a param");
is($p[0],$p, "got the expected param back");

my @pv = $o1->param_values();
is(scalar(@pv),1,"got a param value");
is($pv[0],$v1,"got expected value");

#<>#
note('test "add_param"');
my $p2 = $o1->add_param(name => 'interesting', value => $v2);
ok($p2, "added param 2");

@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),2,"got two params");
is($p[0],$p, "got the expected param 1 back");
is($p[1],$p2, "got the expected param 2 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),2,"got two param values");
is($pv[0],$v1,"got expected value 1");
is($pv[1],$v2,"got expected value 2");

#<>#
note('test "remove_param"');
#$DB::single = 1;
ok($o1->remove_param($p2), "removed param 2");
@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),1,"got one param after removing param 2");
is($p[0],$p, "got the expected param 1 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),1, "got one param value after removeing param 2");
is($pv[0],$v1,"got expected value 1");

#<>#
note('test "add_param_value"');
#$DB::single = 1;
$p2 = $o1->add_param_value(name => 'interesting', value => $v2);
ok($p2, "added another param");

@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),2,"got two params");
is($p[0],$p, "got the expected param 1 back");
is($p[1],$p2, "got the expected param 2 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),2,"got two param values");
is($pv[0],$v1,"got expected value 1");
is($pv[1],$v2,"got expected value 2");

#<>#
note('test "remove_param_value"');
#$DB::single = 1;
ok($o1->remove_param_value($v2), "removed param value 2");
@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),1,"got one param after removing param 2");
is($p[0],$p, "got the expected param 1 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),1, "got one param value after removeing param 2");
is($pv[0],$v1,"got expected value 1");

#<>#
note('test "add_interesting_param_value" with a key-value pair');
#$DB::single = 1;
$p2 = $o1->add_interesting_param_value(value => $v2);
ok($p2, "added an intereting param");
is($p2->name,'interesting', "the param name was set automatically during addition");

@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),2,"got two params");
is($p[0],$p, "got the expected param 1 back");
is($p[1],$p2, "got the expected param 2 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),2,"got two param values");
is($pv[0],$v1,"got expected value 1");
is($pv[1],$v2,"got expected value 2");

#<>#
note('test "remove_interesting_param_value"');
#$DB::single = 1;
ok($o1->remove_interesting_param_value($v2), "removed param value 2");
@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),1,"got one param after removing param 2");
is($p[0],$p, "got the expected param 1 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),1, "got one param value after removeing param 2");
is($pv[0],$v1,"got expected value 1");

#<>#
note('test "add_interesting_param_value" without a key-value pair');
#$DB::single = 1;
$p2 = $o1->add_interesting_param_value($v2);
ok($p2, "added an intereting param");
is($p2->name,'interesting', "the param name was set automatically during addition");

@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),2,"got two params");
is($p[0],$p, "got the expected param 1 back");
is($p[1],$p2, "got the expected param 2 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),2,"got two param values");
is($pv[0],$v1,"got expected value 1");
is($pv[1],$v2,"got expected value 2");

#<>#
note('test "remove_interesting_param_value" again');
#$DB::single = 1;
ok($o1->remove_interesting_param_value($v2), "removed param value 2");
@p = sort { $a->value_id <=> $b->value_id } $o1->params();
is(scalar(@p),1,"got one param after removing param 2");
is($p[0],$p, "got the expected param 1 back");

@pv = sort { $a->id <=> $b->id } $o1->param_values();
is(scalar(@pv),1, "got one param value after removeing param 2");
is($pv[0],$v1,"got expected value 1");

#<>#
#note("test setting an indirect value as a group");
#$o1->interesting_param_values(undef);
#my @v = $o1->interesting_param_values;
#ok(!@v, "no values associated after setting value to undef through has-many mutable accessor")
#    or diag(Data::Dumper::Dumper(\@v));
#@v = $o1->interesting_param_values([$v1,$v2,$v3]);
#is("@v", "$v1 $v2 $v3", "correctly re-set the value list");

#<>#
#$DB::single = 1;
my $thing2 = URT::Thing->create(thing_id => 2, interesting_param_values => [$v1,$v2,$v3]);
ok($thing2, 'Created another Thing');
my @params = $thing2->params();;
is(scalar(@params), 3, 'And it has 3 attached params');
isa_ok($params[0], 'URT::Param');
isa_ok($params[1], 'URT::Param');
isa_ok($params[2], 'URT::Param');

@params = sort { $a->value cmp $b->value } @params;
is($params[0]->name, 'interesting', "param 1's name is interesting");
is($params[1]->name, 'interesting', "param 2's name is interesting");
is($params[2]->name, 'interesting', "param 3's name is interesting");

is($params[0]->value, $v1, "param 1's value is correct");
is($params[1]->value, $v2, "param 2's value is correct");
is($params[2]->value, $v3, "param 3's value is correct");

$v1->p1(1000);
my @values = $thing2->param_values(p1 => 1000);
is(scalar(@values), 1, "got one object back when filtering in an indirect accessor which is two steps away");
is($values[0], $v1, "got the correct object back when filtering in an indirect accessor which his two steps away");
@values = $thing2->param_values();
is(scalar(@values), 3, "got everything back when not filtering with an indirect accessor which is two steps away");

# Try to get the object again w/ id
my $o2 = URT::Thing->get(2);
ok($o2, 'Got thingy w/ id 2');
my @v = $o2->interesting_param_values;
@v = sort { $a->id cmp $b->id } @v;
my @expected = sort { $a->id cmp $b->id } ( $v1, $v2, $v3 );
is_deeply(\@v,\@expected, 'Ineresting values match those from orginal object');
#is_deeply([ $o1->interesting_param_values ], [ $thing2->interesting_param_values ], 'Ineresting values match those from orginal object');

#<>#
note('primitives with UR::Value in where clause');
$o1->add_friend('Watson');
is_deeply([$o1->friends], [qw/ Watson /], 'Added a friend: Watson');
$o1->add_friend('Crick');
is_deeply([sort $o1->friends], [qw/ Crick Watson /], 'Added a friend: Crick');
$o1->remove_friend('Watson');
is_deeply([$o1->friends], [qw/ Crick /], 'Removed a friend: Watson');
$o1->friends(undef);
ok(!$o1->friends, 'Set friends to undef');

# Try to get the object again w/ id and ineresting values
# FIXME does not work
#my $o3 = URT::Thing->get(
#    thing_id => 2,
#    interesting_param_values => ['abc','def'],
#);
#ok($o3, 'Got thingy w/ id 2 and interesting_param_values => [qw/abc def/]');
#is_deeply([ $o->interesting_param_values ], [ $o3->interesting_param_values ], 'Ineresting values match those from original object');

