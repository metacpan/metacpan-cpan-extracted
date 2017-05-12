use strict;
use warnings;

use UR;
use Test::More tests => 11;

# This test is to reproduce a poor error message that was received
# when trying to access an indirect object which contained an invalid
# class name. In the previous case this simply died to trying to call
# __meta__ on an undefined value within the accessor sub of
# mk_id_based_object_accessor.

class TestClass {
    has => [
        other_class => { is => 'Text' },
        other_id => { is => 'Number' },
        other => { is => 'UR::Object', id_class_by => 'other_class', id_by => 'other_id'},
   ],
};

class RelatedThing {
    id_by => 'id',
    has => [
        name => { is => 'String' }
    ],
};


my $a = TestClass->create(other_class => 'NonExistent', other_id => '1234');

my $other = eval { $a->other };

ok(! $other, 'Calling id_class_by accessor with bad data threw exception');
like($@,
    qr(Can't resolve value for 'other' on class TestClass id),
    'Exception looks ok');


my $related = RelatedThing->create(name => 'bob');
my $b = TestClass->create(other_class => 'RelatedThing', other_id => $related->id);
ok($b, 'Created thing');

is($b->other->id, $related->id, "Thing's other accessor returne the previously created object");

# Wheels are attached to things.
# Clocks have wheels.
class Clock {
    has_many => [
        wheels => { is => 'Wheel', reverse_as => 'attached_to' }
    ],
};

class Wheel {
    has => [
        attached_to => { is => 'UR::Object', id_class_by => 'attached_to_class', id_by => 'attached_to_id' }
    ],
};

my $clock = Clock->create();

my $clock_wheel0 = Wheel->create(attached_to_class => 'Clock', attached_to_id => $clock->id);
my $clock_wheel1 = Wheel->create(attached_to_class => 'Clock', attached_to_id => $clock->id);
my $clock_wheel2 = Wheel->create(attached_to_class => 'Clock', attached_to_id => $clock->id);

my @clock_wheels = $clock->wheels();
is(scalar(@clock_wheels), 3, 'Clock has 3 wheels');
is($clock_wheels[0]->id, $clock_wheel0->id, 'Wheel 0 has correct ID');
is($clock_wheels[1]->id, $clock_wheel1->id, 'Wheel 1 has correct ID');
is($clock_wheels[2]->id, $clock_wheel2->id, 'Wheel 2 has correct ID');


# Vehicles also have wheels.  Motorcycles are vehicles.
class Vehicle {
    is_abstract => 1,
    has_many => [
        wheels => { is => 'Wheel', reverse_as => 'attached_to' }
    ],
};
class Motorcycle {
    is => 'Vehicle'
};

my $moto = Motorcycle->create();
my $moto_wheel0 = Wheel->create(attached_to_class => 'Motorcycle', attached_to_id => $moto->id);
my $moto_wheel1 = Wheel->create(attached_to_class => 'Motorcycle', attached_to_id => $moto->id);

my @moto_wheels = $moto->wheels();
is(scalar(@moto_wheels), 2, 'Motorcycle has 2 wheels');
is($moto_wheels[0]->id, $moto_wheel0->id, 'Wheel 0 has correct ID');
is($moto_wheels[1]->id, $moto_wheel1->id, 'Wheel 1 has correct ID');


