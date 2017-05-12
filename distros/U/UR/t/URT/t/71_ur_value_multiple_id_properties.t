use strict;
use warnings;
use Test::More tests => 90;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Scalar::Util;

UR::Object::Type->define(
    is => 'UR::Value',
    class_name => 'URT::InflatableDefaultSerializer',
    id_by => ['prop_a','prop_b'],
);

UR::Object::Type->define(
    is => 'UR::Value',
    class_name => 'URT::InflatableCustomSerializer',
    id_by => ['prop_a', 'prop_b'],
);

sub URT::InflatableCustomSerializer::__deserialize_id__ {
    my($class, $id) = @_;
    my %h;
    @h{'prop_a','prop_b'} = split(':', $id);
    return \%h;
}

sub URT::InflatableCustomSerializer::__serialize_id__ {
    my($class, $props) = @_;
    return join(':', @$props{'prop_a','prop_b'});
}

test_create_single();
test_get_single();

test_get_multiple();


sub test_create_single {
    foreach my $test ( [ 'URT::InflatableDefaultSerializer', "\t" ],
                       [ 'URT::InflatableCustomSerializer', ':' ],
    ) {
        my($test_class, $id_sep) = @$test;
        note("create single $test_class");

        $test_class->dump_error_messages(0); # Supress normal errors
        my @failed_create_params = ( [], [prop_a => 'foo' ], [prop_b => 'foo']);
        foreach my $params ( @failed_create_params ) {
            my $o = $test_class->create(@$params);
            ok(! $o, "Cannot create $test_class object with only ".scalar(@$params).' params');
        }

        $test_class->dump_error_messages(0); # back on

        my $o = $test_class->create(prop_a => 'foo', prop_b => 'bar');
        ok($o, "Created $test_class object with both named parameters");
        _properties_match($o, prop_a => 'foo', prop_b => 'bar', id => join($id_sep, 'foo','bar'));

        my $o2 = $test_class->get($o->id);
        is( Scalar::Util::refaddr($o),
            Scalar::Util::refaddr($o2),
            "re-getting the same $test_class returns the same instance");
        _properties_match($o2, prop_a => 'foo', prop_b => 'bar', id => join($id_sep, 'foo','bar'));


        $o = $test_class->create(id => join($id_sep, 'baz','quux'));
        ok($o, "Created $test_class object with id");
         _properties_match($o, prop_a => 'baz', prop_b => 'quux', id => join($id_sep, 'baz','quux'));

        $o2 = $test_class->get($o->id);
        is( Scalar::Util::refaddr($o),
            Scalar::Util::refaddr($o2),
            "re-getting the same $test_class returns the same instance");
        _properties_match($o2, prop_a => 'baz', prop_b => 'quux', id => join($id_sep, 'baz','quux'));
    }
}

sub test_get_single {
    foreach my $test ( [ 'URT::InflatableDefaultSerializer', "\t" ],
                       [ 'URT::InflatableCustomSerializer', ':' ],
    ) {
        my($test_class, $id_sep) = @$test;
        note("get single $test_class");
    
        my $o = $test_class->get(prop_a => 'a', prop_b => 'b');
        ok($o, 'get() with both named parameters');
        _properties_match($o, prop_a => 'a', prop_b => 'b', id => join($id_sep, 'a','b'));

        my $o2 = $test_class->get($o->id);
        is( Scalar::Util::refaddr($o),
            Scalar::Util::refaddr($o2),
            're-getting the same object returns the same instance');
         _properties_match($o, prop_a => 'a', prop_b => 'b', id => join($id_sep, 'a','b'));


        $o = $test_class->get(id => join($id_sep, 'c','d'));
        ok($o, 'get InflatableFromId with both named parameters');
        _properties_match($o, prop_a => 'c', prop_b => 'd', id => join($id_sep, 'c','d'));

        $o2 = $test_class->get($o->id);
        is( Scalar::Util::refaddr($o),
            Scalar::Util::refaddr($o2),
            're-getting the same object returns the same instance');
        _properties_match($o, prop_a => 'c', prop_b => 'd', id => join($id_sep, 'c','d'));
    }
}


sub test_get_multiple {
    foreach my $test ( [ 'URT::InflatableDefaultSerializer', "\t" ],
                       [ 'URT::InflatableCustomSerializer', ':' ],
    ) {
        my($test_class, $id_sep) = @$test;
        note("get multiple $test_class");

        my @o = $test_class->get(id => [
                                    join($id_sep, 'e','f'),
                                    join($id_sep, 'g','h'),
                                    join($id_sep, 'i','j'),
                                ]);
        is(scalar(@o), 3, 'Get 3 objects by composite ID');

        _properties_match($o[0], prop_a => 'e', prop_b => 'f', id => join($id_sep, 'e','f'));
        _properties_match($o[1], prop_a => 'g', prop_b => 'h', id => join($id_sep, 'g','h'));
        _properties_match($o[2], prop_a => 'i', prop_b => 'j', id => join($id_sep, 'i','j'));
    }
}

sub _properties_match {
    my $o = shift;

    while(my $prop = shift) {
        my $val = shift;
        is($o->$prop, $val, "property $prop");
    }
}

