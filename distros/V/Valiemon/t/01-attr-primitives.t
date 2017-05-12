use strict;
use warnings;

use Test::More;

use Valiemon;
use JSON::XS qw();
use JSON::PP qw();
use Types::Serialiser;

use_ok 'Valiemon::Primitives';

subtest 'is_object' => sub {
    my $p = Valiemon::Primitives->new;
    ok  $p->is_object({});
    ok !$p->is_object([]);
    ok !$p->is_object('hello');
    ok !$p->is_object(12.3);
    ok !$p->is_object(4);
    ok !$p->is_object(1);
    ok !$p->is_object(undef)
};

subtest 'is_array' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_array({});
    ok  $p->is_array([]);
    ok !$p->is_array('hello');
    ok !$p->is_array(12.3);
    ok !$p->is_array(4);
    ok !$p->is_array(1);
    ok !$p->is_array(undef)
};

subtest 'is_string' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_string({});
    ok !$p->is_string([]);
    ok  $p->is_string('hello');
    TODO :{
        local $TODO = 'weak typing !!';
        ok !$p->is_string(12.3);
        ok !$p->is_string(4);
        ok !$p->is_string(1);
    }
    ok !$p->is_string(undef)
};

subtest 'is_number' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_number({});
    ok !$p->is_number([]);
    ok !$p->is_number('hello');
    ok  $p->is_number(12.3);
    ok  $p->is_number(4);
    TODO : {
        local $TODO = 'weak typing !!';
        ok !$p->is_number(1);
    }
    ok !$p->is_number(undef);
    ok !$p->is_number(JSON::XS::true);
    ok !$p->is_number(JSON::XS::false);
};

subtest 'is_integer' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_integer({});
    ok !$p->is_integer([]);
    ok !$p->is_integer('hello');
    ok !$p->is_integer(12.3);
    ok  $p->is_integer(4);
    TODO : {
        local $TODO = 'weak typing !!';
        ok !$p->is_integer(1);
    }
    ok !$p->is_integer(undef)
};

subtest 'is_boolean' => sub {
    my $p_perl = Valiemon::Primitives->new(+{ use_json_boolean => 0 });
    ok  $p_perl->is_boolean(Types::Serialiser::true);
    ok  $p_perl->is_boolean(1);
    ok !$p_perl->is_boolean({});
    ok !$p_perl->is_boolean('hoge');
    ok !$p_perl->is_boolean(\1);
    ok !$p_perl->is_boolean(\0);

    my $p_json = Valiemon::Primitives->new(+{ use_json_boolean => 1 });
    ok  $p_json->is_boolean(Types::Serialiser::true);
    ok  $p_json->is_boolean(\1);
    ok  $p_json->is_boolean(\0);
    ok !$p_json->is_boolean(1);
    ok !$p_json->is_boolean({});
    ok !$p_json->is_boolean('hoge');
};

subtest 'is_boolean_perl' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_boolean_perl({});
    ok !$p->is_boolean_perl([]);
    ok !$p->is_boolean_perl('hello');
    ok !$p->is_boolean_perl(12.3);
    ok !$p->is_boolean_perl(4);
    ok  $p->is_boolean_perl(1);
    ok !$p->is_boolean_perl(undef);
    ok !$p->is_boolean_perl(\1);
    ok !$p->is_boolean_perl(\0);
    TODO : {
        local $TODO = 'invalidate 0.0';
        ok !$p->is_boolean_perl(0.0);
    }

    ok $p->is_boolean_perl(JSON::XS::true);
    ok $p->is_boolean_perl(JSON::XS::false);
    ok $p->is_boolean_perl(JSON::PP::true);
    ok $p->is_boolean_perl(JSON::PP::false);
    ok $p->is_boolean_perl(Types::Serialiser::true);
    ok $p->is_boolean_perl(Types::Serialiser::false);
};

subtest 'is_boolean_json' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_boolean_json({});
    ok !$p->is_boolean_json([]);
    ok !$p->is_boolean_json('hello');
    ok !$p->is_boolean_json(12.3);
    ok !$p->is_boolean_json(4);
    ok !$p->is_boolean_json(1);
    ok !$p->is_boolean_json(0.0);
    ok !$p->is_boolean_json(undef);
    ok  $p->is_boolean_json(\1);
    ok  $p->is_boolean_json(\0);

    ok $p->is_boolean_json(JSON::XS::true);
    ok $p->is_boolean_json(JSON::XS::false);
    ok $p->is_boolean_json(JSON::PP::true);
    ok $p->is_boolean_json(JSON::PP::false);
    ok $p->is_boolean_json(Types::Serialiser::true);
    ok $p->is_boolean_json(Types::Serialiser::false);
};

subtest 'is_null' => sub {
    my $p = Valiemon::Primitives->new;
    ok !$p->is_null({});
    ok !$p->is_null([]);
    ok !$p->is_null('hello');
    ok !$p->is_null(12.3);
    ok !$p->is_null(4);
    ok !$p->is_null(1);
    ok  $p->is_null(undef);
};

subtest 'is_equal' => sub {
    my $p = Valiemon::Primitives->new;

    note 'null';
    ok !$p->is_equal(undef, {});
    ok !$p->is_equal(undef, []);
    ok !$p->is_equal(undef, '');
    ok !$p->is_equal(undef, 0.0);
    ok !$p->is_equal(undef, 0);
    ok !$p->is_equal(undef, 1);
    ok  $p->is_equal(undef, undef);

    note 'bool';
    ok !$p->is_equal(0, {});
    ok !$p->is_equal(0, []);
    ok !$p->is_equal(0, '');
    TODO : {
        local $TODO = 'implement boolean handling';
        ok !$p->is_equal(0, 0.0);
        ok !$p->is_equal(0, 0); # integer
    }
    ok  $p->is_equal(0, 0); # bool
    ok !$p->is_equal(0, undef);

    note 'string';
    ok !$p->is_equal('', {});
    ok !$p->is_equal('', []);
    ok  $p->is_equal('', '');
    ok  $p->is_equal('hello', 'hello');
    ok !$p->is_equal('', 0.0);
    ok !$p->is_equal('', 0);
    ok !$p->is_equal('', 1);
    ok !$p->is_equal('', undef);

    note 'number';
    ok !$p->is_equal(0, {});
    ok !$p->is_equal(0, []);
    ok !$p->is_equal(0, '');
    ok  $p->is_equal(0, 0.0); # it's ok
    ok  $p->is_equal(0, 0);
    ok !$p->is_equal(0, 1);
    ok !$p->is_equal(0, undef);

    note 'array';
    ok !$p->is_equal([], {});
    ok  $p->is_equal([], []);
    ok  $p->is_equal([1, 2, 3], [1, 2, 3]);
    ok !$p->is_equal([1, 2, 3], [1, 3, 2]);
    ok !$p->is_equal([], '');
    ok !$p->is_equal([], 0.0);
    ok !$p->is_equal([], 0);
    ok !$p->is_equal([], 1);
    ok !$p->is_equal([], undef);

    note 'object';
    ok  $p->is_equal({}, {});
    ok  $p->is_equal({ a => 1, b => 2 }, { b => 2, a => 1 });
    ok !$p->is_equal({ a => 1, b => 1 }, { b => 2, a => 1 });
    ok !$p->is_equal({}, []);
    ok !$p->is_equal({}, '');
    ok !$p->is_equal({}, 0.0);
    ok !$p->is_equal({}, 0);
    ok !$p->is_equal({}, 1);
    ok !$p->is_equal({}, undef);

    note 'use_json_boolean';
    my $pj = Valiemon::Primitives->new(+{ use_json_boolean => 1 });
    ok !$pj->is_equal(JSON::XS::true, 1);
    ok !$pj->is_equal(JSON::XS::false, 0);
};

done_testing;
