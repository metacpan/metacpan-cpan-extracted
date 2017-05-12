use strict;
use warnings;

use Test::More tests => 14;

use File::Basename;
use lib File::Basename::dirname(__FILE__).'/../../../lib';
use lib File::Basename::dirname(__FILE__).'/../..';

# Tests that for two entities with bridge objects connecting them one can
# efficiently retrieve all of the associated entities across the bridge

use URT;

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;
ok($dbh, 'Got a database handle');

ok($dbh->do('create table PERSON
             ( person_id int NOT NULL PRIMARY KEY, name varchar )'),
    'created person table');

ok($dbh->do('create table CLUB
             ( club_id int NOT NULL PRIMARY KEY, name varchar )'),
    'created club table');

ok($dbh->do('create table MEMBERSHIP
             ( membership_id int NOT NULL PRIMARY KEY, person_id int references PERSON(person_id), club_id int references CLUB(club_id))'),
    'created membership table');

ok(UR::Object::Type->define(
    class_name => 'URT::Person',
    table_name => 'PERSON',
    id_by => [
        person_id => { is => 'NUMBER' },
    ],
    has => [
        name => { is => 'String' },
        memberships => { is => 'URT::Membership', is_many => 1, reverse_as => 'member' },
        clubs => { is => 'URT::Club', is_many => 1, via => 'memberships', to => 'club' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'created class for people');

ok(UR::Object::Type->define(
    class_name => 'URT::Club',
    table_name => 'CLUB',
    id_by => [
        club_id => { is => 'NUMBER' },
    ],
    has => [
        name => { is => 'String' },
        memberships => { is => 'URT::Membership', is_many => 1, reverse_as => 'club' },
        members => { is => 'URT::Person', is_many => 1, via => 'memberships', to => 'member' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'created class for clubs');

ok(UR::Object::Type->define(
    class_name => 'URT::Membership',
    table_name => 'MEMBERSHIP',
    id_by => [
        membership_id => { is => 'NUMBER' },
    ],
    has => [
        person_id => { is => 'NUMBER' },
        member => { is => 'URT::Person', id_by => 'person_id' },
        club_id => { is => 'CLUB' },
        club => { is => 'URT::Club', id_by => 'club_id' },
    ],
    data_source => 'URT::DataSource::SomeSQLite',
),
'created class for people');


#insert data
#Alice, Bob, and Charlie are members of Club A
#Alice, Charlie, and Darlene are members of Club B
#Alice and Charlie are members of Club C
#Alice is a member of Club D
my $insert = $dbh->prepare('insert into person values (?,?)');
for my $row ([1, 'Alice'], [2, 'Bob'], [3, 'Charlie'], [4, 'Darlene']) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into club values (?,?)');
for my $row ([100, 'Club A'], [200, 'Club B'], [300, 'Club C'], [400, 'Club D']) {
    $insert->execute(@$row);
}
$insert->finish();

$insert = $dbh->prepare('insert into membership values (?,?,?)');
for my $row ([101, 1, 100], [102, 2, 100], [103, 3, 100],
             [201, 1, 200], [203, 3, 200], [204, 4, 200],
             [301, 1, 300], [303, 3, 300],
             [401, 1, 400],
            ){
    $insert->execute(@$row);
}

my $query_count = 0;
my $query_text = '';

ok(URT::DataSource::SomeSQLite->create_subscription(
    method => 'query',
    callback => sub { $query_text = $_[0]; $query_count++}
),
'created a subscription for query');

my $person = URT::Person->get(1);
ok($person, 'Got person object');

$query_count = 0;
my @clubs = $person->clubs();
is(scalar(@clubs), 4, 'got all 4 clubs of which person is a member');
is($query_count, '2', 'made 2 queries total'); #one to get memberships, one to get clubs

my $club = URT::Club->get(200);
ok($club, 'Got club object');

$query_count = 0;
my @members = $club->members();
is(scalar(@members), 3, 'got all 3 members of the club');
is($query_count, '2', 'made 2 queries total'); #one to get memberships, one to get members

