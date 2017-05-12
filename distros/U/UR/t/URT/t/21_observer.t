#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 42;

UR::Object::Type->define(
    class_name => 'URT::Parent',
    is_abstract => 1,
    valid_signals => [qw(last_name something_else)],
);

UR::Object::Type->define(
    class_name => 'URT::Person',
    is => 'URT::Parent',
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

foreach my $thing ( $p1,$p2,'URT::Person','URT::Parent') {
    foreach my $aspect ( '','last_name','something_else' ) {
        my $id = ref($thing) ? $thing->id : $thing;
        my %args = ( callback => sub { no warnings 'uninitialized'; $observations->{$id}->{$aspect}++ } );
        if ($aspect) {
            $args{'aspect'} = $aspect;
        }
        ok($thing->add_observer(%args), "Made an observer on $thing for aspect $aspect");
    }
}



$change_count = get_change_count();
is($p1->last_name("Doh!"),"Doh!", "changed person 1");
is_deeply($observations,
          { 1             => { '' => 1, 'last_name' => 1 },
            'URT::Person' => { '' => 1, 'last_name' => 1 },
            'URT::Parent' => { '' => 1, 'last_name' => 1 },
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, '1 change recorded');


$change_count = get_change_count();
$observations = {};
is($p2->last_name("Do"),"Do", "changed person 2");
is_deeply($observations,
          { 2             => { '' => 1, 'last_name' => 1 },
            'URT::Person' => { '' => 1, 'last_name' => 1 },
            'URT::Parent' => { '' => 1, 'last_name' => 1 },
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, '1 change recorded');


$change_count = get_change_count();
$observations = {};
ok($p2->__signal_observers__('something_else'),'send the "something_else" signal to person 2');
is_deeply($observations,
          { 2             => { '' => 1, 'something_else' => 1},
            'URT::Person' => { '' => 1, 'something_else' => 1},
            'URT::Parent' => { '' => 1, 'something_else' => 1},
          },
          'Callbacks were fired');
is(get_change_count(), $change_count, 'no changes recorded for non-change signal');


$change_count = get_change_count();
$observations = {};
ok(URT::Person->__signal_observers__('something_else'), 'Send the "something_else" signal to the URT::Person class');
is_deeply($observations,
          { 1             => { '' => 1, 'something_else' => 1},
            2             => { '' => 1, 'something_else' => 1},
            'URT::Person' => { '' => 1, 'something_else' => 1},
            'URT::Parent' => { '' => 1, 'something_else' => 1},
          },
          'Callbacks were fired');
is(get_change_count(), $change_count, 'no changes recorded for non-change signal');

$change_count = get_change_count();
$observations = {};
# Signals don't propagate down the inheritance tree, only up
ok(URT::Parent->__signal_observers__('something_else'), 'Send the "something_else" signal to the URT::Parent class');
is_deeply($observations,
          { 'URT::Parent' => { '' => 1, 'something_else' => 1},
          },
          'Callbacks were fired');



$change_count = get_change_count();
$observations = {};
ok(URT::Person->__signal_observers__('blablah'), 'Send the "blahblah" signal to the URT::Person class');
is_deeply($observations,
          { 1             => { '' => 1,},
            2             => { '' => 1,},
            'URT::Person' => { '' => 1,},
            'URT::Parent' => { '' => 1,},
          },
          'Callbacks were fired');
is(get_change_count(), $change_count, 'no changes recorded for non-change signal');


ok(scalar($p1->remove_observers()), 'Remove observers for Person 1');


$change_count = get_change_count();
$observations = {};
is($p1->last_name("Doooo"),"Doooo", "changed person 1");
is_deeply($observations,
          { 'URT::Person' => { '' => 1, 'last_name' => 1 },
            'URT::Parent' => { '' => 1, 'last_name' => 1 }
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, '1 change recorded');


$change_count = get_change_count();
$observations = {};
is($p2->last_name("Boo"),"Boo", "changed person 2");
is_deeply($observations,
          { 'URT::Person' => { '' => 1, 'last_name' => 1 },
            'URT::Parent' => { '' => 1, 'last_name' => 1 },
            2             => { '' => 1, 'last_name' => 1 },
          },
          'Callbacks were fired');
is(get_change_count(), $change_count + 1, '1 change recorded');


subtest 'once observers' => sub {
    plan tests => 12;

    my($parent_observer_fired, $person_observer_fired) = (0,0);
    ok(my $person_obs = URT::Person->add_observer(aspect => 'last_name', once => 1, callback => sub { $person_observer_fired++ } ),
        'Add once observer to "last_name" aspect of URT::Person');
    ok(my $parent_obs = URT::Parent->add_observer(aspect => 'last_name', once => 1, callback => sub { $parent_observer_fired++ } ),
        'Add once observer to "last_name" aspect of URT::Parent');

    $observations = {};
    ok($p1->last_name('once'), 'changed person 1');
    is_deeply($observations,
              { 'URT::Person' => { '' => 1, 'last_name' => 1 },
                'URT::Parent' => { '' => 1, 'last_name' => 1 },
              },
              'Regular callbacks were fired') or diag explain $observations;
    is($parent_observer_fired, 1, '"once" observer on URT::Parent was fired');
    is($person_observer_fired, 1, '"once" observer on URT::Person was fired');

    isa_ok($person_obs, 'UR::DeletedRef', 'Person observer is deleted');
    isa_ok($parent_obs, 'UR::DeletedRef', 'Parent observer is deleted');

    ($parent_observer_fired, $person_observer_fired) = (0,0);
    $observations = {};
    ok($p1->last_name('once again'), 'changed person 1');
    is_deeply($observations,
              { 'URT::Person' => { '' => 1, 'last_name' => 1 },
                'URT::Parent' => { '' => 1, 'last_name' => 1 },
              },
              'Regular callbacks were fired') or diag explain $observations;
    is($parent_observer_fired, 0, '"once" observer on URT::Parent was not fired');
    is($person_observer_fired, 0, '"once" observer on URT::Person was not fired');
};

subtest 'once observer is removed before callback run' => sub {
    plan tests => 5;

    my $obj = URT::Person->create(first_name => 'bob', last_name => 'schmoe');
    my $callback_run = 0;
    our $in_observer = 0;
    my $observer = $obj->add_observer(aspect => 'first_name',
                                      once => 1,
                                      callback => sub {
                                          my($obj, $aspect, $old, $new) = @_;
                                          local $in_observer = $in_observer + 1;
                                          die "recursive call to observer" if $in_observer > 1;
                                          $obj->$aspect($new . $new);  # double up the new value
                                          $callback_run++;
                                      }
                                    );
    $obj->first_name('changed');
    is($obj->first_name, 'changedchanged', 'Observer modified the new value');
    is($callback_run, 1, 'callback was run once');
    isa_ok($observer, 'UR::DeletedRef', 'Observer is deleted');


    $callback_run = 0;
    $obj->first_name('bob');
    is($obj->first_name, 'bob', 'Changed value back');
    is($callback_run, 0, 'Callback was not run');
};


sub get_change_count {
    my @c = map { scalar($_->__changes__) } URT::Person->get;
    my $sum = 0;
    do {$sum += $_ } foreach (@c);
    return $sum;
}

