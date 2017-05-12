use warnings;
use strict;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 31;

UR::Object::Type->define(
    class_name => 'Acme',
    is => ['UR::Namespace'],
);


UR::Object::Type->define(
    class_name => "Acme::Boss",
    has => [
        id   => { type => "Number" },
        name => { type => "String" },
    ]
);

UR::Object::Type->define(
    class_name => 'Acme::Employee',
    has => [
        name => { type => "String" },
        #boss => { type => "Acme::Boss", id_by => [ boss_id => { type => "Number" } ] },
        boss => { type => "Acme::Boss", id_by => 'boss_id' },
    ]
);

my $c = Acme::Employee->__meta__;
my @p = sort $c->all_property_names;
is_deeply(\@p, [qw/boss_id name/], "got expected old-style properties");

ok(Acme::Employee->can("boss_id"), "has an accessor for the fk property.");
ok(Acme::Employee->can("boss"), "has an accessor for the object.");

my $b1 = Acme::Boss->create(name => "Bossy", id => 1000);
ok($b1, "made a boss");

my $b2 = Acme::Boss->create(name => "Crabby", id => 2000);
ok($b2, "made another boss");

ok($b1 != $b2, "boss objects are different");
ok($b1->id != $b2->id, "boss ids are different");

my $e = Acme::Employee->create(name => "Shifty", id => 3000, boss_id => $b1->id);
ok($e, "made an employee");

is($e->boss_id,$b1->id, "the boss is assigned correctly when using the id at creation time and getting the id");
is($e->boss,$b1, "the boss is assigned correctly when using the id at creation time and getting the object");

is($e->boss($b2),$b2, "assigned a different boss object");
is($e->boss_id, $b2->id, "boss id is okay");
is($e->boss, $b2, "boss object is okay");

is($e->boss(undef), undef, "Set the boss to undef");
is($e->boss_id, undef, "No boss_id on the new employee");
is($e->boss, undef, "No boss on the new employee");

is($e->boss($b1), $b1, "Set the boss back to a real object");
is($e->boss,$b1, "the boss is object is back");
is($e->boss_id, $b1->id, "boss id is back too");

is($e->boss_id(undef), undef, "Set the id to undef");
is($e->boss_id, undef, "No boss_id on the new employee");
is($e->boss, undef, "No boss on the new employee");


my $e2 = Acme::Employee->create(name => "Nappy");
ok($e2, "Made a new employee");

is($e2->boss_id, undef, "No boss_id on the new employee");
is($e2->boss, undef, "No boss on the new employee");

is($e->boss($b1), $b1, "set one boss to one object");
is($e2->boss($b2), $b2, "set another boss to the other object");
ok($e->boss != $e2->boss, "boss objects differ as expected");


my $e3 = Acme::Employee->create(name => "Snappy", boss => $b1);
ok($e3, "Made a new employee with a boss property");

is($e3->boss, $b1, "No boss on the new employee");
is($e3->boss_id, $b1->id, "No boss_id on the new employee");


 
