use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

use Data::Dumper;
use Test::More;
plan tests => 14;

UR::Object::Type->define(
    class_name => 'URT::Param',
    id_by => [
        thing_id => { is => 'Number' },
        name => { is => 'String' },
        value => { is => 'String'},
    ],
    has => [
        thing => { is => 'URT::Thing', id_by => 'thing_id' },
    ],
);
UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        'thing_id' => { is => 'Number' },
    ],
    has => [
        params => { is => 'URT::Param', reverse_as => 'thing', is_many => 1 },
        # Actually, either of these property definitions will work
        interesting_param_values => { via => 'params', to => 'value', is_many => 1, is_mutable => 1,
                                      where => [ name => 'interesting'] },
        bob_param_value => { via => 'params', to => 'value', where => [name => 'bob'] },

        #interesting_params => { is => 'URT::Param', reverse_as => 'thing', is_many => 1,
        #                        where => [name => 'interesting']},
        #interesting_param_values => { via => 'interesting_params', to => 'value', is_many => 1, is_mutable => 1 },
    ],
);


# make a non-interesting one ahead of time
URT::Param->create(thing_id => 2, name => 'uninteresting', value => '123');

my $o = URT::Thing->create(thing_id => 2, interesting_param_values => ['abc','def']);
ok($o, 'Created another Thing');
my @params = $o->params();
is(scalar(@params), 3, 'And it has 3 attached params');
isa_ok($params[0], 'URT::Param');
isa_ok($params[1], 'URT::Param');
isa_ok($params[2], 'URT::Param');

@params = sort { $a->value cmp $b->value } @params;
is($params[0]->name, 'uninteresting', "param 1's name is uninteresting");
is($params[1]->name, 'interesting', "param 2's name is interesting");
is($params[2]->name, 'interesting', "param 3's name is interesting");

is($params[0]->value, '123', "param 1's value is correct");
is($params[1]->value, 'abc', "param 2's value is correct");
is($params[2]->value, 'def', "param 3's value is correct");

# Try to get the object again w/ id
my $o2 = URT::Thing->get(2);
ok($o2, 'Got thingy w/ id 2');
is_deeply([ $o->interesting_param_values ], [ $o2->interesting_param_values ], 'Ineresting values match those from orginal object');

my @o = URT::Thing->get(bob_param_value => undef);
is(scalar(@o), 1, 'Got one thing back with no bob_param_value');



# Try to get the object again w/ id and ineresting values
# FIXME does not work
#my $o3 = URT::Thing->get(
#    thing_id => 2,
#    interesting_param_values => ['abc','def'],
#);
#ok($o3, 'Got thingy w/ id 2 and interesting_param_values => [qw/abc def/]');
#is_deeply([ $o->interesting_param_values ], [ $o3->interesting_param_values ], 'Ineresting values match those from original object');

