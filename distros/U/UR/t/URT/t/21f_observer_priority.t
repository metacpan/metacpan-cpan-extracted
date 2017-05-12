#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 8;

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
    valid_signals => ['something_else'],
);

my $p1 = URT::Person->create(
    id => 1, first_name => "John", last_name => "Doe"
);
ok($p1, "Made a person");

my $p2 = URT::Person->create(
    id => 2, first_name => "Jane", last_name => "Doe"
);
ok($p2, "Made another person");


my $observer_counter = 0;

$p1->last_name("DoDo");
is($observer_counter, 0, 'No change in the observer counter when no observers are active');

my %observer_records;
my $o1_p1 = $p1->add_observer(callback => sub { $observer_records{'o1_p1'} = $observer_counter++ },
                              aspect   => 'last_name',
                              priority => 9);
my $o2_p1 = $p1->add_observer(callback => sub { $observer_records{'o2_p1'} = $observer_counter++ },
                              aspect   => 'last_name',
                              priority => 0);
my $o3_p2 = $p2->add_observer(callback => sub { $observer_records{'o3_p2'} = $observer_counter++ },
                              aspect   => 'last_name',
                              priority => 8);
my $o4_p2 = $p2->add_observer(callback => sub { $observer_records{'o4_p2'} = $observer_counter++ },
                              aspect   => 'last_name',
                              priority => 1);
my $o5_c1 = URT::Person->add_observer(callback => sub { $observer_records{'o5_c1'} = $observer_counter++ },
                              aspect   => 'last_name',
                              priority => 7);
my $o6_c1 = URT::Person->add_observer(callback => sub { $observer_records{'o6_c1'} = $observer_counter++ },
                              priority => 2);
my $o7_p1 = $p1->add_observer(callback => sub { $observer_records{'o7_p1'} = $observer_counter++ },
                              priority => 6);
my $o8_p1 = $p1->add_observer(callback => sub { $observer_records{'o8_p1'} = $observer_counter++ },
                              priority => 3);
my $o9_p2 = $p2->add_observer(callback => sub { $observer_records{'o9_p2'} = $observer_counter++ },
                              priority => 5);
my $o10_p2 = $p2->add_observer(callback => sub { $observer_records{'o10_p2'} = $observer_counter++ },
                              priority => 4);


$observer_counter = 0;
%observer_records = ();
is($p1->last_name("Doh!"),"Doh!", "changed person 1");
is_deeply(\%observer_records,
          { 'o2_p1' => 0,
            'o6_c1' => 1,
            'o8_p1' => 2,
            'o7_p1' => 3,
            'o5_c1' => 4,
            'o1_p1' => 5 },
          'Observers fired in the correct order');

ok($o1_p1->priority(-1), 'Change observer priority from lowest to highest');

$observer_counter = 0;
%observer_records = ();
is($p1->last_name("foo!"),"foo!", "changed person 1");
is_deeply(\%observer_records,
          { 'o1_p1' => 0,
            'o2_p1' => 1,
            'o6_c1' => 2,
            'o8_p1' => 3,
            'o7_p1' => 4,
            'o5_c1' => 5 },
          'Observers fired in the correct order');

