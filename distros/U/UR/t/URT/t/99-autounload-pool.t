use strict;
use warnings;
use Test::More tests=> 8;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

setup_classes();

subtest 'normal operation' => sub {
    plan tests => 7;
    my $kept = URT::Thing->get(1);
    my $also_kept = URT::Thing->get(related_number => 2);
    do {
        my $unloader = UR::Context::AutoUnloadPool->create();
        URT::Thing->get(98);
        URT::Thing->get(related_number => 2);  # re-get something gotten in the outer scope
        URT::Thing->get(related_number => 99);
    };
    ok(URT::Thing->is_loaded(id => $kept->id), 'URT::Thing is still loaded');
    ok(URT::Thing->is_loaded(id => $also_kept->id), 'other URT::Thing is still loaded');
    ok(URT::Related->is_loaded(id => $also_kept->id), 'URT::Related is still loaded');

    foreach my $id ( 98, 99 ) {
        ok(! URT::Thing->is_loaded(id => $id), "Expected URT::Thing $id was unloaded");
        ok(! URT::Related->is_loaded(id => $id), "Expected URT::Related $id was unloaded");
    }
};

subtest 'do not unload changed objects' => sub {
    plan tests => 2;

    my $changed_id = 99;
    my $unchanged_id = 98;
    do {
        my $unloader = UR::Context::AutoUnloadPool->create();
        my $changed_thing = URT::Thing->get($changed_id);
        $changed_thing->changable_prop(1000);

        URT::Thing->get($unchanged_id);
    };
    ok(URT::Thing->is_loaded($changed_id), 'Changed object did not get unloaded');
    ok(! URT::Thing->is_loaded($unchanged_id), 'Unchanged object did get unloaded');
};

subtest 'object destructor does not unload changed objects' => sub {
    plan tests => 2;

    my $changed_id = 99;
    my $unchanged_id = 98;
    do {
        my $changed_thing;
        do {
            my $unloader = UR::Context::AutoUnloadPool->create();
            $changed_thing = URT::Thing->get($changed_id);

            URT::Thing->get($unchanged_id);
        };
        $changed_thing->changable_prop(1000);
    };
    ok(URT::Thing->is_loaded($changed_id), 'Changed object did not get unloaded');
    ok(! URT::Thing->is_loaded($unchanged_id), 'Unchanged object did get unloaded');
};

subtest 'call delete on pool' => sub {
    plan tests => 2;

    my $kept_id = 100;
    do {
        my $unloader = UR::Context::AutoUnloadPool->create();
        URT::Thing->get($kept_id);

        ok($unloader->delete, 'Delete the auto unloader');
    };
    ok(URT::Thing->is_loaded($kept_id), 'Object was not unloaded');
};

subtest 'does not unload meta objects' => sub {
    plan tests => 3;
    ok(! UR::Object::Type->is_loaded('URT::Thingy'), 'URT::Thingy is not loaded yet');
    do {
        my $unloader = UR::Context::AutoUnloadPool->create();
        URT::Thingy->class;  # Load a class in the URT namespace
    };
    ok(UR::Object::Type->is_loaded('URT::Thingy'), 'Class object is still loaded');
    ok(UR::Object::Property->is_loaded(class_name => 'URT::Thingy', property_name => 'enz_id'),
        "Class' property object is still loaded");
};

subtest 'with iterator' => sub {
    URT::Thing->unload();
    URT::Related->unload();

    plan tests => 5;

    my $iter = URT::Thing->create_iterator();
    for (my $expected = 1; $expected <= 5; $expected++) {
        my $unloader = UR::Context::AutoUnloadPool->create();
        my $obj = $iter->next();
        is($obj->id, $expected, "Got Thing ID $expected")
            || diag("Fetched object ID is ".$obj->id);
    }
};

subtest 'works with UR::Value objects' => sub {
   plan tests => 4;
   ok(! UR::Object::Type->is_loaded('UR::Value::Integer'), 'UR::Value::Integer is not loaded yet.');
    do {
        my $unloader = UR::Context::AutoUnloadPool->create();
        my $integer = UR::Value::Integer->get(23);
        isa_ok($integer, 'UR::Value', 'got value inside pool');
    };

    ok( UR::Object::Type->is_loaded('UR::Value::Integer'), 'UR::Value::Integer is loaded now.');
    my $integer = UR::Value::Integer->get(24);
    isa_ok($integer, 'UR::Value', 'got value outside pool');
};

subtest 'works with singletons' => sub {
    plan tests => 4;
    ok(!defined $URT::Singleton::singleton, 'no URT::Singleton loaded');

    do {
        my $unloader = UR::Context::AutoUnloadPool->create();
        my $singleton = URT::Singleton->get();
        isa_ok($singleton, 'UR::Singleton', 'created a singleton');
        is($singleton, $URT::Singleton::singleton, 'URT::Singleton loaded');
    };
    my $singleton = URT::Singleton->get();
    ok($singleton, 'reloaded singleton after pool unloaded it');
};

sub setup_classes {
    my $generic_loader = sub {
        my($class_name, $rule, $expected_headers) = @_;
        my $value_width = scalar(@$expected_headers);

        if ($rule->template->_property_names) {
            # get() with filters
            my $value;
            foreach my $prop ( $rule->template->_property_names ) {
                if ($value = $rule->value_for($prop)) {
                    last;
                }
            }

            my @value = ($value) x $value_width;
            return ($expected_headers, [ \@value ] );

        } else {
            # get() with no filters
            # return a closure that will start at '1' and go up
            my $value = 0;
            my $iterator = sub {
                $value++;
                return [ ($value) x $value_width ];
            };
            return ($expected_headers, $iterator);
        }
    };

    class URT::Related {
        id_by => 'id',
        data_source => 'UR::DataSource::Default',
    };
    *URT::Related::__load__ = $generic_loader;
    
    class URT::Thing {
        id_by => 'id',
        has => [
            changable_prop => { is => 'Number' },
            related => { is => 'URT::Related', id_by => 'id' },
            related_number => { via => 'related', to => 'id' },
        ],
        data_source => 'UR::DataSource::Default',
    };
    *URT::Thing::__load__ = $generic_loader;

    class URT::Singleton {
        is => 'UR::Singleton',
        has => [
            single_value => { is => 'Number' },
        ],
        data_source => 'UR::DataSource::Default',
    };
}
