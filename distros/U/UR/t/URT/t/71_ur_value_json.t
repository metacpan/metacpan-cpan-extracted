use strict;
use warnings;
use Test::More tests => 4;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;


UR::Object::Type->define(
    is => 'UR::Value::JSON',
    class_name => 'URT::JSONTestValue',
    id_by => ['prop_a','prop_b'],
);

subtest 'create' => sub {
    plan tests => 1;

    my $obj = URT::JSONTestValue->create(prop_a => 'tc_a', prop_b => 'tc_b');
    my $expected_id = '{"prop_a":"tc_a","prop_b":"tc_b"}';
    is( $obj->id,$expected_id, 'id is expected json (create)');
};

subtest 'get from properties' => sub {
    plan tests => 1;

    my $obj = URT::JSONTestValue->get(prop_a => 'tgfp_a', prop_b => 'tgfp_b');
    my $expected_id = '{"prop_a":"tgfp_a","prop_b":"tgfp_b"}';
    is($obj->id, $expected_id, 'id is expected json (get)');
};

subtest 'get by single id' => sub {
    plan tests => 2;

    my $obj = URT::JSONTestValue->get('{"prop_a":"gs_a","prop_b":"gs_b"}');
    is($obj->prop_a,'gs_a',  'prop_a matches (single)');
    is($obj->prop_b, 'gs_b', 'prop_b matches (single)');
};

subtest 'get by multiple id' => sub {
    plan tests => 4;

    my @objs = URT::JSONTestValue->get(id => [
        '{"prop_a":"gm1_a","prop_b":"gm1_b"}',
        '{"prop_a":"gm2_a","prop_b":"gm2_b"}',
    ]);
    is($objs[0]->prop_a, 'gm1_a', 'prop_a matches (multiple 1)');
    is($objs[0]->prop_b, 'gm1_b', 'prop_b matches (multiple 1)');
    is($objs[1]->prop_a, 'gm2_a', 'prop_a matches (multiple 2)');
    is($objs[1]->prop_b, 'gm2_b', 'prop_b matches (multiple 2)');
};
