#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use UR;
use MRO::Compat;

setup_test_env();

test_namespace_valid_values_mro();
test_namespace_gets_default_mro();

test_gryphon_object_methods_follow_dfs_mro();
test_gryphon_inheritance_follows_dfs_mro();
test_class_property_follows_dfs_mro();
test_package_sub_follows_dfs_mro();

if ($^V lt 5.9.5) {
    my $namespace = C3Animal->get();
    is($namespace->method_resolution_order, 'dfs', 'MRO reverted to DFS on a C3 namespace if Perl < 5.9.5');
    note('Skipping C3 tests because Perl < 5.9.5.');
} else {
    test_gryphon_object_methods_follow_c3_mro();
    test_gryphon_inheritance_follows_c3_mro();
    test_class_property_follows_c3_mro();
    test_package_sub_follows_c3_mro();
}

done_testing();

sub test_namespace_valid_values_mro {
    my $namespace = Animal->get();
    my $property = $namespace->__meta__->property('method_resolution_order');
    if ($^V lt 5.9.5) {
        is_deeply($property->valid_values, ['dfs'], 'valid MRO for Perl < 5.9.5 is only DFS');
    } else {
        is_deeply($property->valid_values, ['dfs', 'c3'], 'valid MRO for Perl >= 5.9.5 is DFS and C3');
    }
}

sub test_namespace_gets_default_mro {
    my $animal_namespace = Animal->get();
    isa_ok($animal_namespace, 'UR::Namespace', 'got Animal namespace');

    # This is meant to check that the namespace has the default value of method_resolution_order
    # populated on get unlike non-singleton objects which are only populated on create.
    ok($animal_namespace->can('method_resolution_order'), 'namespace can method_resolution_order') || return;
    ok($animal_namespace->method_resolution_order, 'namespace has a method_resolution_order');
}

#######################
# DFS Based Namespace #
#######################

sub test_gryphon_object_methods_follow_dfs_mro {
    my $animal = DfsAnimal::Animal->create();
    my $lion = DfsAnimal::Lion->create();
    my $eagle = DfsAnimal::Eagle->create();
    my $gryphon = DfsAnimal::Gryphon->create();
    is($lion->foo, $animal->foo, "Lion's foo is the same as Animal's");
    isnt($eagle->foo, $animal->foo, "Eagle's foo is not the same as Animal's");
    is($gryphon->foo, $animal->foo, "Gryphon's foo is the same as Animal's");
}

sub test_gryphon_inheritance_follows_dfs_mro {
    my $gryphon = DfsAnimal::Gryphon->create();
    isa_ok($gryphon, 'DfsAnimal::Gryphon', '$gryphon isa DfsAnimal::Gryphon');
    isa_ok($gryphon, 'DfsAnimal::Lion', '$gryphon isa DfsAnimal::Lion');
    isa_ok($gryphon, 'DfsAnimal::Eagle', '$gryphon isa DfsAnimal::Eagle');

    is(mro::get_mro('DfsAnimal::Gryphon'), 'dfs', "Gryphon's MRO is DFS");

    my $i = 0;
    my $mro_linear_isa = mro::get_linear_isa('DfsAnimal::Gryphon');
    my %inheritance = map { $_ => $i++ } @$mro_linear_isa;
    ok($inheritance{'DfsAnimal::Lion'} < $inheritance{'DfsAnimal::Eagle'}, 'Lion is higher precendence than Eagle');
    ok($inheritance{'DfsAnimal::Eagle'} > $inheritance{'UR::Object'}, 'Eagle is lower precendence than UR::Object');
}

sub test_class_property_follows_dfs_mro {
    # This is theoretically the same check as comparing $gryphon->foo to $eagle->foo
    # However, it appears that property resolution is different than method resolution
    # since property resolution is done by hand and is probably a breadth first search.
    my $meta = UR::Object::Type->get(class_name => 'DfsAnimal::Gryphon');
    my $foo_property_meta = $meta->property_meta_for_name('foo');
    is($foo_property_meta->class_name, 'DfsAnimal::Eagle', "Gryphon is using Eagle's foo");

    my $foo_property = $meta->property('foo');
    is($foo_property->class_name, 'DfsAnimal::Eagle', "Gryphon is using Eagle's foo");
}

sub test_package_sub_follows_dfs_mro {
    is(DfsAnimal::Animal->species(), 'Animal', "Make sure we installed species sub in Animal");

    is(DfsAnimal::Eagle->species(), 'Eagle', "Make sure we installed species sub in Eagle");

    is(DfsAnimal::Gryphon->species(), 'Animal', "Gryphon called Animal's species sub");
}

######################
# C3 Based Namespace #
######################

sub test_gryphon_object_methods_follow_c3_mro {
    my $animal = C3Animal::Animal->create();
    my $lion = C3Animal::Lion->create();
    my $eagle = C3Animal::Eagle->create();
    my $gryphon = C3Animal::Gryphon->create();
    is($lion->foo, $animal->foo, "Lion's foo is the same as Animal's");
    isnt($eagle->foo, $animal->foo, "Eagle's foo is not the same as Animal's");
    is($gryphon->foo, $eagle->foo, "Gryphon's foo is the same as Eagle's");
}

sub test_gryphon_inheritance_follows_c3_mro {
    my $gryphon = C3Animal::Gryphon->create();
    isa_ok($gryphon, 'C3Animal::Gryphon', '$gryphon isa C3Animal::Gryphon');
    isa_ok($gryphon, 'C3Animal::Lion', '$gryphon isa C3Animal::Lion');
    isa_ok($gryphon, 'C3Animal::Eagle', '$gryphon isa C3Animal::Eagle');

    is(mro::get_mro('C3Animal::Gryphon'), 'c3', "Gryphon's MRO is C3");

    my $i = 0;
    my $mro_linear_isa = mro::get_linear_isa('C3Animal::Gryphon');
    my %inheritance = map { $_ => $i++ } @$mro_linear_isa;
    ok($inheritance{'C3Animal::Lion'} < $inheritance{'C3Animal::Eagle'}, 'Lion is higher precendence than Eagle');
    ok($inheritance{'C3Animal::Eagle'} < $inheritance{'UR::Object'}, 'Eagle is higher precendence than UR::Object');
}

sub test_class_property_follows_c3_mro {
    # This is theoretically the same check as comparing $gryphon->foo to $eagle->foo
    # However, it appears that property resolution is different than method resolution
    # since property resolution is done by hand and is probably a breadth first search.
    my $meta = UR::Object::Type->get(class_name => 'C3Animal::Gryphon');
    my $foo_property_meta = $meta->property_meta_for_name('foo');
    is($foo_property_meta->class_name, 'C3Animal::Eagle', "Gryphon is using Eagle's foo");

    my $foo_property = $meta->property('foo');
    is($foo_property->class_name, 'C3Animal::Eagle', "Gryphon is using Eagle's foo");
}

sub test_package_sub_follows_c3_mro {
    is(C3Animal::Animal->species(), 'Animal', "Make sure we installed species sub in Animal");

    is(C3Animal::Eagle->species(), 'Eagle', "Make sure we installed species sub in Eagle");

    is(C3Animal::Gryphon->species(), 'Eagle', "Gryphon called Eagle's species sub");
}

sub setup_test_env {
    no warnings 'once';

    my $animal_namespace_type = UR::Object::Type->define(
        class_name => 'Animal',
        is => 'UR::Namespace',
    );
    isa_ok($animal_namespace_type, 'UR::Object::Type', 'defined Animal namespace');

    #######################
    # DFS Based Namespace #
    #######################

    my $dfs_animal_namespace_type = UR::Object::Type->define(
        class_name => 'DfsAnimal',
        is => 'UR::Namespace',
        has => [
            method_resolution_order => {
                is => 'Text',
                default_value => 'dfs',
            },
        ],
    );
    isa_ok($dfs_animal_namespace_type, 'UR::Object::Type', 'defined DfsAnimal namespace');
    my $dfs_animal_namespace = DfsAnimal->get();
    isa_ok($dfs_animal_namespace, 'UR::Namespace', 'got DfsAnimal namespace');
    is($dfs_animal_namespace->method_resolution_order, 'dfs', "DfsAnimal's MRO is DFS");

    my $dfs_animal_type = UR::Object::Type->define(
        class_name => 'DfsAnimal::Animal',
        has => [
            foo => {
                is_constant => 1,
                calculate => q(
                    return 'Animal';
                ),
            },
        ],
    );
    isa_ok($dfs_animal_type, 'UR::Object::Type', 'defined Animal');
    is($dfs_animal_type->namespace, 'DfsAnimal', 'DfsAnimal::Animal is in Animal namespace');
    *DfsAnimal::Animal::species = sub { 'Animal' };

    my $dfs_lion_type = UR::Object::Type->define(
        class_name => 'DfsAnimal::Lion',
        is => 'DfsAnimal::Animal',
    );
    isa_ok($dfs_lion_type, 'UR::Object::Type', 'defined DfsAnimal::Lion');

    my $dfs_eagle_type = UR::Object::Type->define(
        class_name => 'DfsAnimal::Eagle',
        is => 'DfsAnimal::Animal',
        has => [
            foo => {
                is_constant => 1,
                calculate => q(
                    return 'Eagle';
                ),
            },
        ],
    );
    isa_ok($dfs_eagle_type, 'UR::Object::Type', 'defined DfsAnimal::Eagle');
    no warnings 'redefine';
    *DfsAnimal::Eagle::species = sub { 'Eagle' };
    use warnings 'redefine';

    my $dfs_gryphon_type = UR::Object::Type->define(
        class_name => 'DfsAnimal::Gryphon',
        is => ['DfsAnimal::Lion', 'DfsAnimal::Eagle'],
    );
    isa_ok($dfs_gryphon_type, 'UR::Object::Type', 'defined DfsAnimal::Gryphon');

    ######################
    # C3 Based Namespace #
    ######################

    my $c3_animal_namespace_type = UR::Object::Type->define(
        class_name => 'C3Animal',
        is => 'UR::Namespace',
        has => [
            method_resolution_order => {
                is => 'Text',
                default_value => 'c3',
            },
        ],
    );
    isa_ok($c3_animal_namespace_type, 'UR::Object::Type', 'defined C3Animal namespace');
    my $c3_animal_namespace = C3Animal->get();
    isa_ok($c3_animal_namespace, 'UR::Namespace', 'got C3Animal namespace');
    is($c3_animal_namespace->method_resolution_order, 'c3', "C3Animal's MRO is C3");

    my $c3_animal_type = UR::Object::Type->define(
        class_name => 'C3Animal::Animal',
        has => [
            foo => {
                is_constant => 1,
                calculate => q(
                    return 'Animal';
                ),
            },
        ],
    );
    isa_ok($c3_animal_type, 'UR::Object::Type', 'defined Animal');
    is($c3_animal_type->namespace, 'C3Animal', 'C3Animal::Animal is in Animal namespace');
    *C3Animal::Animal::species = sub { 'Animal' };

    my $c3_lion_type = UR::Object::Type->define(
        class_name => 'C3Animal::Lion',
        is => 'C3Animal::Animal',
    );
    isa_ok($c3_lion_type, 'UR::Object::Type', 'defined C3Animal::Lion');

    my $c3_eagle_type = UR::Object::Type->define(
        class_name => 'C3Animal::Eagle',
        is => 'C3Animal::Animal',
        has => [
            foo => {
                is_constant => 1,
                calculate => q(
                    return 'Eagle';
                ),
            },
        ],
    );
    isa_ok($c3_eagle_type, 'UR::Object::Type', 'defined C3Animal::Eagle');
    no warnings 'redefine';
    *C3Animal::Eagle::species = sub { 'Eagle' };
    use warnings 'redefine';

    my $c3_gryphon_type = UR::Object::Type->define(
        class_name => 'C3Animal::Gryphon',
        is => ['C3Animal::Lion', 'C3Animal::Eagle'],
    );
    isa_ok($c3_gryphon_type, 'UR::Object::Type', 'defined C3Animal::Gryphon');

    use warnings 'once';
}
