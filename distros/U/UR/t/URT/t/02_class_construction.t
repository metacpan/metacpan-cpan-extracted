#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 35;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

my $c1 = UR::Object::Type->define(class_name => 'URT::Foo', data_source => "URT::DataSource::SomeSQLite", table_name => "FOO");
is($URT::Foo::ISA[0], 'UR::Entity', "defined class has correct inheritance");
is($URT::Foo::Type::ISA[0], 'UR::Entity::Type', "defined class' meta class has correct inheritance");

my $c1b = UR::Object::Type->get(data_source_id => "URT::DataSource::SomeSQLite", table_name => "FOO");
is($c1b,$c1, "defined class is gettable");

my $c2 = UR::Object::Type->create(class_name => 'URT::Bar', data_source => "URT::DataSource::SomeSQLite", table_name => "BAR");
is($URT::Bar::ISA[0], 'UR::Entity', "created class has correct inheritance");
is($URT::Bar::Type::ISA[0], 'UR::Entity::Type', "created class' meta class has correct inheritance");

my $c2b = UR::Object::Type->get(data_source_id => "URT::DataSource::SomeSQLite", table_name => "BAR");
is($c2b,$c2, "created class is gettable");

my $c3_parent = UR::Object::Type->define(
                    class_name => 'URT::BazParent',
                    id_by => ['id_prop_a','id_prop_b'],
                    has => [
                        id_prop_a => { is => 'Integer' },
                        id_prop_b => { is => 'String' },
                        prop_c    => { is => 'Number' },
                    ],
                );
ok($c3_parent, 'Created a parent class');
is($URT::BazParent::ISA[0], 'UR::Object', 'defined class has correct inheritance');
is($URT::BazParent::Type::ISA[0], 'UR::Object::Type', "defined class' meta class has correct inheritance");
my %props = map { $_->property_name => $_ } $c3_parent->properties;
is(scalar(keys %props), 4, 'Parent class property count correct');
is($props{'id_prop_a'}->is_id, '0 but true', 'id_prop_a is an ID property and has the correct rank');
is($props{'id_prop_b'}->is_id, '1', 'id_prop_b is an ID property and has the correct rank');
is($props{'prop_c'}->is_id, undef, 'prop_c is not an ID property');

my %id_props = map { $_->property_name => 1 } $c3_parent->id_properties;
is(scalar(keys %id_props), 3, 'Parent class id property count correct');
is_deeply(\%id_props,
          { id_prop_a => 1, id_prop_b => 1, id => 1 },
          'all ID properties are there');
        
my $c3 = UR::Object::Type->define(
             class_name => 'URT::Baz',
             is => 'URT::BazParent',
             has => [
                 prop_d    => { is => 'Number' },
             ],
          );
ok($c3, 'Created class with some properties and a parent class');
is($URT::Baz::ISA[0], 'URT::BazParent', 'defined class has correct inheritance');
is($URT::Baz::Type::ISA[0], 'URT::BazParent::Type', "defined class' meta class has correct inheritance");
%props = map { $_->property_name => $_ } $c3->properties;
is(scalar(keys %props), 5, 'property count correct');
is($props{'id_prop_a'}->is_id, '0 but true', 'id_prop_a is an ID property and has the correct rank');
is($props{'id_prop_b'}->is_id, '1', 'id_prop_b is an ID property and has the correct rank');
is($props{'prop_c'}->is_id, undef, 'prop_c is not an ID property');
is($props{'prop_d'}->is_id, undef, 'prop_d is not an ID property');


my $other_class = UR::Object::Type->define(
    class_name => 'URT::OtherClass',
    id_by => [
        id => { is => 'String' },
    ],
);
my $parent_with_id_prop = UR::Object::Type->define(
    class_name => 'URT::ParentWithProp',
    has => [
        other_id => { is => 'Integer' },
    ],
);

my $child_without_id_prop = UR::Object::Type->define(
    class_name => 'URT::ChildWithoutProp',
    is => 'URT::ParentWithProp',
    has => [
        other => { is => 'URT::OtherClass', id_by => 'other_id' }
    ],
);
is($child_without_id_prop->property_meta_for_name('other_id')->data_type,
    'Integer',
    'implied property gets data_type from parent when specified');


# Test that the id_generator value propogates properly

# in-memory class
UR::Object::Type->define(
    class_name => 'URT::InMemory',
    id_by => 'id'
);
is(URT::InMemory->__meta__->id_generator,
    '-urinternal',
    'in-memory class gets default id generator');

# usual case, use the data-source's default sequence generator based on the column and
# table name.  Blank value in the class meta means delegate to the data source
UR::Object::Type->define(
    class_name => 'URT::DS_No_Idgen',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'ds_no_idgen',
    id_by => 'id'
);
is(URT::DS_No_Idgen->__meta__->id_generator,
    undef,
    'parent SQL-stored class has blank id_generator');

UR::Object::Type->define(
    is => 'URT::DS_No_Idgen',
    class_name => 'URT::DS_No_Idgen::Child',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'ds_no_idgen_child',
    id_by => 'id'
);
is(URT::DS_No_Idgen::Child->__meta__->id_generator,
    undef,
    'child SQL-stored class has blank id_generator');

# Parent does not specify id_generator, child does
UR::Object::Type->define(
    is => 'URT::DS_No_Idgen',
    class_name => 'URT::DS_No_Idgen::Child_has_idgen',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'ds_no_idgen_child_has_idgen',
    id_generator => 'ds_no_idgen_child_has_idgen_seq',
    id_by => 'id'
);
is(URT::DS_No_Idgen::Child_has_idgen->__meta__->id_generator,
    'ds_no_idgen_child_has_idgen_seq',
    'Child SQL-stored class can override blank id_generator from parent');

# Parent specifies a sequence generator, the child uses the same one by default
UR::Object::Type->define(
    class_name => 'URT::DS_seq_idgen',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'ds_seq_idgen',
    id_generator => 'id_seq_idgen_seq',
    id_by => 'id',
);
is(URT::DS_seq_idgen->__meta__->id_generator,
    'id_seq_idgen_seq',
    'parent SQL-stored class has sequence id_generator');

UR::Object::Type->define(
    is => 'URT::DS_seq_idgen',
    class_name => 'URT::DS_seq_idgen::Child',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'ds_seq_idgen_child',
    id_by => 'id',
);
is(URT::DS_seq_idgen::Child->__meta__->id_generator,
    'id_seq_idgen_seq',
    "child SQL-stored class has parent's sequence id_generator");

# Parent specifies a sequence generator, child specifies a different one
UR::Object::Type->define(
    is => 'URT::DS_seq_idgen',
    class_name => 'URT::DS_seq_idgen::Child2',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'ds_seq_idgen_child2',
    id_generator => 'id_seq_idgen_child2_seq',
    id_by => 'id',
);
is(URT::DS_seq_idgen::Child2->__meta__->id_generator,
    'id_seq_idgen_child2_seq',
    'child class can specify a different sequence generator than parent');

# parent has uuid generator, child is blank and should inherit the parent's value
UR::Object::Type->define(
    class_name => 'URT::Uuid_idgen',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'uuid_idgen',
    id_generator => '-uuid',
    id_by => 'id',
);
is(URT::Uuid_idgen->__meta__->id_generator,
    '-uuid',
    'parent SQL-stored class uses uuid id_generator');

UR::Object::Type->define(
    is => 'URT::Uuid_idgen',
    class_name => 'URT::Uuid_idgen::Child',
    table_name => 'uuid_idgen_child',
    id_by => 'id',
);
is(URT::Uuid_idgen::Child->__meta__->id_generator,
    '-uuid',
    'child SQL-stored class definition has blank is_generator, but inherits parent value uuid');


subtest 'property_for_column()' => sub {
    plan tests => 26;

    my $parent_meta = UR::Object::Type->define(
        class_name => 'URT::PropForColumnParent',
        id_by => 'parent_id',
        has => [
            foo => { is => 'String' },
            bar => { is => 'Number', column_name => 'bar_custom' },
        ],
        table_name => 'parent_table',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    my $child_meta = UR::Object::Type->define(
        class_name => 'URT::PropForColumnChild',
        is => 'URT::PropForColumnParent',
        id_by => 'child_id',
        has => [
            foo => { is => 'String' },
            bar => { is => 'Number', column_name => 'bar' },
            baz => { is => 'Number' },
        ],
        table_name => 'child_table',
        data_source => 'URT::DataSource::SomeSQLite',
    );

    my $do_tests = sub {
        my($class_meta, @tests) = @_;

        for (my $i = 0; $i < @tests; $i += 2) {
            my($column_name, $expected_property_name) = @tests[$i, $i+1];

            is($class_meta->property_for_column($column_name),
                $expected_property_name,
                $class_meta->class_name . " column $column_name");
        }
    };

    my @parent_tests = (
        parent_id => 'parent_id',
        bogus => undef,
        bar => undef,
        bar_custom => 'bar',
        'parent_table.parent_id' => 'parent_id',
        'parent_table.bogus' => undef,
        'parent_table.bar' => undef,
        'parent_table.bar_custom' => 'bar',
        'bogus_table.parent_id' => undef,
    );

    $do_tests->($parent_meta, @parent_tests);

    my @child_tests = (
        parent_id => 'parent_id',
        child_id => 'child_id',
        bogus => undef,
        foo => 'foo',
        bar => 'bar',
        bar_custom  => 'bar',
        baz => 'baz',
        'parent_table.parent_id' => 'parent_id',
        'child_table.parent_id' => undef,
        'parent_table.child_id' => undef,
        'child_table.child_id' => 'child_id',
        'parent_table.bar' => undef,
        'child_table.bar' => 'bar',
        'parent_table.bar_custom' => 'bar',
        'child_table.bar_custom' => undef,
        'parent_table.baz' => undef,
        'child_table.baz' => 'baz',
    );

    $do_tests->($child_meta, @child_tests);
};

subtest 'inline view property_for_column()' => sub {
    plan tests => 6;

    my $class_meta = UR::Object::Type->define(
        class_name => 'URT::ClassWithInlineView',
        id_by => 'id',
        has => [ 'prop_a', 'prop_b' ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => '(select id, prop_a, prop_b from class_with_inline_view where id is not null) class_with_inline_view',
    );

    my @tests = (
        'id' => 'id',
        'prop_a' => 'prop_a',
        'bogus' => undef,
        'class_with_inline_view.prop_a' => 'prop_a',
        'class_with_inline_view.bogus' => undef,
        'bogus_table.prop_a' => undef,
    );

    for (my $i = 0; $i < @tests; $i += 2) {
        my($column_name, $expected_property_name) = @tests[$i, $i+1];
        is($class_meta->property_for_column($column_name),
            $expected_property_name,
            "column $column_name");
    }
};
