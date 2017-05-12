use strict;
use warnings;
use Test::More tests => 35;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

my $co = UR::Object::Type->define(
    class_name => 'URT::Parent',
);
ok($co, 'Defined a parent, non-singleton class');
    
$co = UR::Object::Type->define(
    class_name => 'URT::SomeSingleton',
    is => ['UR::Singleton', 'URT::Parent'],
    has => [
        property_a => { is => 'String' },
    ],
);
ok($co, 'Defined URT::SomeSingleton class');

$co = UR::Object::Type->define(
    class_name => 'URT::ChildSingleton',
    is => [ 'URT::SomeSingleton','UR::Singleton' ],
    has => [
        property_b => { is => 'String' },
    ],
);
ok($co, 'Defined URT::ChildSingleton class');

$co = UR::Object::Type->define(
    class_name => 'URT::GrandChild',
    is => [ 'URT::ChildSingleton'],
);
ok($co, 'Defined URT::GrandChild class');
ok(URT::GrandChild->create(id => 'URT::GrandChild', property_a => 'foo', property_b=>'bar'), 'Created a URT::GrandChild object');
   


my $obj = URT::SomeSingleton->_singleton_object();
ok($obj, 'Got the URT::SomeSingleton object through _singleton_object()');
isa_ok($obj, 'URT::SomeSingleton');

is($obj->property_a('hello'), 'hello', 'Setting property_a on URT::SomeSingleton object');
is($obj->property_a(), 'hello', 'Getting property_a on URT::SomeSingleton object');
is($obj->{property_a}, 'hello', 'Object key was filled in');
is(URT::SomeSingleton->property_a(), 'hello', "Getting property via singleton's class");

is(URT::SomeSingleton->property_a('bye'), 'bye', "Setting property_a on URT::SomeSingleton class");
is($obj->property_a(), 'bye', 'Getting property_a on URT::SomeSingleton object');
is($obj->{property_a}, 'bye', 'Object key was filled in');
is(URT::SomeSingleton->property_a(), 'bye', "Getting property via singleton's class");




my $obj2 = URT::SomeSingleton->get();
ok($obj2, 'Calling get() on URT::SomeSingleton returns an object');
is_deeply($obj,$obj2, 'The two objects are the same');




$obj = URT::ChildSingleton->_singleton_object();
ok($obj, 'Got the URT::ChildSingleton object through _singleton_object()');
isa_ok($obj, 'URT::ChildSingleton');
isa_ok($obj, 'URT::SomeSingleton');

is($obj->property_a('foo'), 'foo', 'Setting property_a on URT::ChildSingleton object');
is($obj->property_a(), 'foo', 'Getting property_a on URT::ChildSingleton object');

is($obj->property_b('blah'), 'blah', 'Setting property_b on URT::ChildSingleton object');
is($obj->property_b(), 'blah', 'Getting property_b on URT::ChildSingleton object');


$obj2 = URT::ChildSingleton->get();
ok($obj2, 'Calling get() on URT::ChildSingleton returns an object');
is_deeply($obj,$obj2, 'The two objects are the same');


my @objs = URT::Parent->get();
is(scalar(@objs), 3, 'get() via parent class returns 3 objects');


ok($obj->delete(), 'Delete the URT::ChildSingleton');
@objs = URT::Parent->get();
is(scalar(@objs), 2, 'get() via parent class returns 2 objects');



$co = UR::Object::Type->define(
    class_name => 'URT::ROSingleton',
    is => ['UR::Singleton'],
    has => [
        property_a => { is => 'String', value => '123abc', is_mutable => 0 },
    ],
);
ok($co, 'Defined URT::ROSingleton class with read-only property');
$obj = URT::ROSingleton->_singleton_object;
ok($obj, 'Get the URT::ROSingleton object through _singleton_object()');
is(URT::ROSingleton->property_a, '123abc', 'read-only property has current value as class method');
is($obj->property_a, '123abc', 'read-only property has current value as instance method');
ok(! eval {$obj->property_a('different') }, 'Setting a different value fails');
like($@,
    qr(Cannot change read-only property property_a for class URT::ROSingleton),
    'exception is correct');
