use Test::More;

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

plan tests => 14;

use_ok('UR::Object::Type::ModuleWriter');

eval {
    my $f = \&UR::Object::Type::_quoted_value;
    my @tests = (
        [q(123), q(123)],
        [q(1.23), q(1.23)],
        [q(abc), q('abc')],
        [q(a'c), q(q(a'c))],
    );
    for my $test (@tests) {
        my ($i, $e) = @$test;
        is($f->($i), $e, "_quoted_value matched: $i");
    }
};

eval {
    my $f = \&UR::Object::Type::_idx;
    my @tests = (
        ['is', 0],
        ['foo', 2],
    );
    for my $test (@tests) {
        my ($i, $e) = @$test;
        is($f->($i), $e, "_idx matched: $i");
    }
};

eval {
    my $f = \&UR::Object::Type::_sort_keys;
    my @i = qw(foo bar is baz);
    my @e = qw(is bar baz foo);
    my @o = $f->(@i);
    is_deeply(\@o, \@e, "_sort_keys matched: " . join(', ', @i));
};

eval {
    my $f = \&UR::Object::Type::_exclude_items;
    my @i = qw(foo bar baz qux);
    my @x = qw(foo baz);
    my @e = qw(bar qux);
    my @o = $f->(\@i, \@x);
    is_deeply(\@o, \@e, "_exclude_items matched: [" . join(', ', @i) . "], [" . join(', ', @x) . "]");
};

# First, make a couple of classes we can point to
my $c = UR::Object::Type->define(
    class_name => 'URT::Related',
    id_by => [
        related_id  => { is => 'String' },
        related_id2 => { is => 'String' },
    ],
    has => [
        related_value => { is => 'String'},
    ],
);

ok($c, 'Defined URT::Related class');

$c = UR::Object::Type->define(
    class_name => 'URT::Parent',
    type_has => [
        some_type_meta => { is => 'ARRAY', is_optional => 1, },
    ],
    id_by => [
        parent_id => { is => 'String' },
    ],
    has => [
        parent_value => { is => 'String' },
    ],
);
ok($c, 'Defined URT::Parent class');

$c = UR::Object::Type->define(
    class_name => 'URT::Remote',
    id_by => [
        remote_id => { is => 'Integer' },
    ],
    has => [
#        test_obj => { is => 'URT::TestClass', id_by => ['prop1','prop2','prop3'] },
        something => { is => 'String' },
    ],
);
ok($c, 'Defined URT::Remote class');

# Make up a class definition with all the different kinds of properties we can think of...
# FIXME - I'm not sure how the attributes_have and id_implied stuff is meant to work
my $test_class_definition = q(
    is => 'URT::Parent',
    table_name => 'PARENT_TABLE',
    type_has => [
        some_new_property => { is => 'Integer', is_optional => 1 },
    ],
    attributes_have => [
        meta_prop_a => { is => 'Boolean', is_optional => 1 },
        meta_prop_b => { is => 'String' },
    ],
    some_type_meta => [ "foo" ],
    subclassify_by => 'my_subclass_name',
    id_by => [
        another_id => { is => 'String', doc => 'blahblah' },
        related => {
            is => 'URT::Related',
            id_by => [ 'parent_id', 'related_id' ],
            doc => 'related',
        },
        foobaz => { is => 'Integer' },
    ],
    has => [
        property_0 => { via => '__self__', to => 'property_a' },
        property_a => { is => 'String', meta_prop_a => 1 },
        property_b => {
            is => 'Integer',
            is_abstract => 1,
            meta_prop_b => 'metafoo',
            doc => q(property'b),
        },
        calc_sql => { calculate_sql => q(to_upper(property_b)) },
        some_enum => {
            is => 'Integer',
            column_name => 'SOME_ENUM',
            valid_values => [ 100, 200, 300 ],
        },
        another_enum => {
            is => 'String',
            column_name => 'different_name',
            valid_values => [ "one", "two", "three", 3, "four" ],
        },
        my_subclass_name => {
            is => 'Text',
            calculate_from => [ 'property_a', 'property_b' ],
            calculate => q("URT::TestClass"),
        },
        subclass_by_prop => { is => 'String' },
        subclass_by_id => { is => 'Integer' },
        subclass_by_obj => {
            is => 'UR::Object',
            id_by => 'subclass_by_id',
            id_class_by => 'subclass_by_prop',
        },
    ],
    has_many => [
        property_cs => { is => 'String', is_optional => 1 },
        remotes => {
            is => 'URT::Remote',
            reverse_as => 'testobj',
            where => [ something => { operator => 'like', value => '%match%' }  ],
        },
        set_remotes => {
            is => 'URT::Remote',
            reverse_as => 'testobj',
            is_mutable => 1,
            where => [ something => { operator => 'like', value => '%match%' }  ],
        },
    ],
    has_optional => [
        property_d => { is => 'Number' },
        calc_perl => {
            calculate_from => [ 'property_a', 'property_b' ],
            calculate => q($property_a . $property_b),
        },
        another_related => {
            is => 'URT::Related',
            id_by => [ 'rel_id1', 'rel_id2' ],
            where => [ 'property_a like' => 'foo', property_b => [ "foo", "bar" ] ],
            is_many => 1,
        },
        related_value => {
            is => 'StringSubclass',
            via => 'another_related',
            is_many => 1,
        },
        related_value2 => {
            is => 'StringSubclass',
            via => 'another_related',
            to => 'related_value',
            is_mutable => 1,
            is_many => 0,
        },
    ],
    schema_name => 'SomeFile',
    data_source => 'URT::DataSource::SomeFile',
    id_generator => 'the_sequence_seq',
    valid_signals => ['nonstandard1', 'something_else', 'third_thing'],
    doc => 'Hi there',
);
my $orig_test_class = $test_class_definition;
my $test_class_meta = eval "UR::Object::Type->define(class_name => 'URT::TestClass', $test_class_definition);";
ok($test_class_meta, 'Defined URT::TestClass class');
if ($@) {
    diag("Errors from class definition:\n$@");
    exit(1);
}

my $string = $test_class_meta->resolve_class_description_perl();
my $orig_string = $string;

# Normalize them by removing newlines, and multiple spaces
$test_class_definition =~ s/\n//gm;
$test_class_definition =~ s/\s+/ /gm;
$string =~ s/\n//gm;
$string =~ s/\s+/ /gm;

my $diffcmd = 'diff -u';

if ($string ne $test_class_definition) {
    ok(0, 'Rewritten class definition matches original');
    IO::File->new('>/tmp/old')->print($orig_test_class);
    IO::File->new('>/tmp/new')->print($orig_string);
    diag(qx($diffcmd /tmp/old /tmp/new));
} else {
    ok(1, 'Rewritten class definition matches original');
}

