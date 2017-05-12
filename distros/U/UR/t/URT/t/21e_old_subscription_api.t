#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 28;

package URT::Person;
UR::Object::Type->define(
    class_name => 'URT::Person',
    has => [
        first_name  => { is => 'String' },
        last_name   => { is => 'String' },
        full_name   => {
            is => 'String',
            calculate_from => ['first_name','last_name'],
            calculate => '$first_name . " " . $last_name',
        }
    ],
);
sub validate_subscription {
    my($class,$method) = @_;
    return 1 if $method eq 'something_else';
    return $class->SUPER::validate_subscription($method);
}

package main;

my $p1 = URT::Person->create(
    id => 1, first_name => "John", last_name => "Doe"
);
ok($p1, "Made a person");

my $p2 = URT::Person->create(
    id => 2, first_name => "Jane", last_name => "Doe"
);
ok($p2, "Made another person");

my $change_count = get_change_count();

my $observations = {};
$p1->last_name("DoDo");
is_deeply($observations, {}, "no callback count change with no observers defined");
is(get_change_count(), $change_count + 1, '1 change recorded even with no observers');

foreach my $thing ( $p1,$p2,'URT::Person') {
    foreach my $aspect ( '','last_name','something_else' ) {
        my $id = ref($thing) ? $thing->id : $thing;
        my %args = ( callback => sub { no warnings 'uninitialized'; $observations->{$id}->{$aspect}++ } );
        if ($aspect) {
            $args{'method'} = $aspect;
        }
        #ok($thing->add_observer(%args), "Made an observer on $thing for aspect $aspect");
        ok($thing->create_subscription(%args), "Made an observer on $thing for aspect $aspect");
    }
}



$change_count = get_change_count();
is($p1->last_name("Doh!"),"Doh!", "changed person 1");
is_deeply($observations,
          { 1             => { '' => 1, 'last_name' => 1 },
            'URT::Person' => { '' => 1, 'last_name' => 1 },
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, '1 change recorded');


$change_count = get_change_count();
$observations = {};
is($p2->last_name("Do"),"Do", "changed person 2");
is_deeply($observations,
          { 2             => { '' => 1, 'last_name' => 1 },
            'URT::Person' => { '' => 1, 'last_name' => 1 },
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, '1 change recorded');


$change_count = get_change_count();
$observations = {};
ok($p2->__signal_change__('something_else'),'send the "something_else" signal to person 2');
is_deeply($observations,
          { 2             => { '' => 1, 'something_else' => 1},
            'URT::Person' => { '' => 1, 'something_else' => 1},
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, 'one change recorded for non-change signal');


$change_count = get_change_count();
$observations = {};
ok(URT::Person->__signal_change__('something_else'), 'Send the "something_else" signal to the URT::Person class');
is_deeply($observations,
          { 1             => { '' => 1, 'something_else' => 1},
            2             => { '' => 1, 'something_else' => 1},
            'URT::Person' => { '' => 1, 'something_else' => 1},
          },
          'Callbacks were fired');
is(get_change_count(), $change_count, 'no changes recorded for non-change signal');


$change_count = get_change_count();
$observations = {};
ok(URT::Person->__signal_change__('blablah'), 'Send the "blahblah" signal to the URT::Person class');
is_deeply($observations,
          { 1             => { '' => 1,},
            2             => { '' => 1,},
            'URT::Person' => { '' => 1,},
          },
          'Callbacks were fired');
is(get_change_count(), $change_count, 'no changes recorded for non-change signal');



sub get_change_count {
    my @c = map { scalar($_->__changes__) } URT::Person->get;
    my $sum = 0;
    do {$sum += $_ } foreach (@c);
    return $sum;
}

