use strict;
use warnings;
use Test::More tests => 21;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

# FIXME - make another test that does something similar but the items are in the DB

UR::Object::Type->define(
    class_name => 'Acme::Person',
    id_by => ['person_id'],
    has => ['name'],
);

UR::Object::Type->define(
    class_name => 'Acme::Employee',
    is => 'Acme::Person',
    has => [ 'title' ],
);

UR::Object::Type->define(
    class_name => 'Acme::Customer',
    is => 'Acme::Person',
    has => [ 'address' ],
);


{ 
    my $p1 = Acme::Employee->create(person_id => 1, name => 'Bob', title => 'worker');
    ok($p1, 'Created employee 1');
    ok($p1->isa('Acme::Employee'), 'Employee 1 isa Acme::Employee');
    ok($p1->isa('Acme::Person'), 'Employee 1 isa Acme::Person');
    ok(! $p1->isa('Acme::Customer'), 'Employee 1 is not a Acme::Customer');
}

{
    my $p2 = Acme::Employee->create(person_id => 2, name => 'Fred', title => 'boss');
    ok($p2, 'Created employee 2');
    ok($p2->isa('Acme::Employee'), 'Employee 2 isa Acme::Employee');
    ok($p2->isa('Acme::Person'), 'Employee 2 isa Acme::Person');
    ok(! $p2->isa('Acme::Customer'), 'Employee 2 is not a Acme::Customer');
}

{
    my $p3 = Acme::Customer->create(person_id => 3, name => 'Joe', address => '123 Main St');
    ok($p3, 'Created customer');
    ok(! $p3->isa('Acme::Employee'), 'Customer is not a Acme::Employee');
    ok($p3->isa('Acme::Person'), 'Customer isa Acme::Person');
    ok($p3->isa('Acme::Customer'), 'Customer isa Acme::Customer');
}

{
    my $p = Acme::Customer->get(person_id => 3);
    ok($p, 'Got a Person with the subclass by id');
    ok($p->isa('Acme::Person'), 'It is a Acme::Person');
    ok($p->isa('Acme::Customer'), 'It is a Acme::Customer');
    ok(! $p->isa('Acme::Employee'), 'It is not a Acme::Employee');
}

{
    my $p = Acme::Person->get(person_id => 3);
    ok($p, 'Got a Person with the base class by id');
    ok($p->isa('Acme::Person'), 'It is a Acme::Person');
    ok($p->isa('Acme::Customer'), 'It is a Acme::Customer');
    ok(! $p->isa('Acme::Employee'), 'It is not a Acme::Employee');
}

{
    my $p = Acme::Employee->get(person_id => 3);
    is($p, undef, 'Getting an employee with the id of a customer correctly returns nothing');
}
