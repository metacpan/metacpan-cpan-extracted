use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;
use Test::More tests => 7;

UR::Object::Type->define(
    class_name => 'Person',
    has => [
        name    => { is => 'String' },
        attribs => { is => 'PersonAttr', is_many => 1, reverse_as => 'person' },
        address => { is => 'String', via => 'attribs', to => 'value', where => [key => 'address'] },
    ],
);

UR::Object::Type->define(
    class_name => 'PersonAttr',
    has => [
        person => { is => 'Person', id_by => 'person_id' },
        key    => { is => 'String' },
        value  => { is => 'String' },
    ],
);

my $bob = Person->create(name => 'Bob');
my $bob_addr = $bob->add_attrib(key => 'address', value => '123 main st');

my $fred = Person->create(name => 'Fred');
my $fred_addr = $fred->add_attrib(key => 'address', value => '456 oak st');

my @people = Person->get(name => 'Fred');
is(scalar(@people), 1, 'Got 1 person named Fred');
is($people[0], $fred, 'it is the right person');

@people = Person->get(address => '123 main st');
is(scalar(@people), 1, 'Got 1 person with address 123 main st');
is($people[0], $bob, 'it is the right person');

ok($fred_addr->value('789 elm st'), 'Change address for Fred');
@people = Person->get(address => '456 oak st');
is(scalar(@people), 0, 'Got 0 people at Fred\' old address');

is($fred->address, '789 elm st', 'Address for Fred is correct through delegated property');
