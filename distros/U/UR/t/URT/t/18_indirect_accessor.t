use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 19;

UR::Object::Type->define(
    class_name => 'Acme',
    is => ['UR::Namespace'],
);

UR::Object::Type->define(
    class_name => "Acme::Boss",
    has => [
        id      => { type => "Number" },
        name    => { type => "String" },
        company => { type => "String" },
    ],
    id_generator => sub { our $boss_seq; ++$boss_seq; },
);

UR::Object::Type->define(
    class_name => 'Acme::Employee',
    has => [
        name => { type => "String" },
        boss => { type => "Acme::Boss", id_by => 'boss_id' },
        boss_name => { via => 'boss', to => 'name' },
        company   => { via => 'boss' },
    ]
);

my $b1 = Acme::Boss->create(name => "Bosser", company => "Some Co.");
ok($b1, "created a boss object");
my $e1 = Acme::Employee->create(boss => $b1);
ok($e1, "created an employee object");
ok($e1->can("boss_name"), "employees can check their boss' name");
ok($e1->can("company"), "employees can check their boss' company");

is($e1->boss_name,$b1->name, "boss_name check works");
is($e1->company,$b1->company, "company check works");

$b1->name("Crabber");
$b1->company("Other Co.");
is($e1->boss_name,$b1->name, "boss_name check works again");
is($e1->company,$b1->company, "company check still works");

my $b2 = Acme::Boss->create(name => "Chief", company => "Yet Another Co.");
ok($b2, "made another boss");
$e1->boss($b2);
is($e1->boss,$b2, "re-assigned the employee to a new boss");
is($e1->boss_name,$b2->name, "boss_name check works");
is($e1->company,$b2->company, "company check works");

# Hmmm... this only triggered the bug on DataSources backed by a real database
my @matches = Acme::Employee->get(boss => 'nonsensical');
ok(scalar(@matches) == 0, 'get employees by boss without boss objects correctly returns 0 items');


my $e2 = Acme::Employee->create(name => 'Bob', boss_name => 'Chief');
ok($e2, 'created an employee via a boss_name that already exists');
is($e2->boss_id, $b2->id, 'boss_id of new employee is correct, did not make a new Acme::Boss');

my %existing_boss_ids = map { $_->id => $_ } Acme::Boss->get();
my $e3 = Acme::Employee->create(name => 'Freddy', boss_name => 'New Boss');
ok($e3, 'Created an employee via a boss_name that did not previously exist');
ok($e3->boss_id, 'it has a boss_id');
ok($e3->boss, 'it has a boss object');
ok(! exists $existing_boss_ids{$e3->boss_id}, 'The new boss_id did not exist before creating this employee');
