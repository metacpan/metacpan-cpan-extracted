use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 17;
use URT::DataSource::SomeSQLite;

# This tests a get() where the filtering property has several levels of indirection
# - A Person has a Job, which has a Location, which has a phone number
# - A Person's phone number for their job can be linked together a couple
#   of different ways
#     1) 
#        a) Location has a phone number
#        b) Job has-a location, id-by the location_id property
#        c) Job has-a phone number via the Location
#        d) Person has-a Job, linked with the job_id property
#        e) Person has-a job_phone, via the Job (which is via the Location)
#     2) a,b same as above
#        c) Person has-a location_id via the Job
#        d) Person has-a Location, id-by the location_id (which is via the Job)
#        e) Person has-a work_phone, via the Location

&setup_classes_and_db();

# This is the way we usually do a doubly-indirect property
my $person = URT::Person->get(job_phone => '456-789-0123');
ok($person, 'get() returned an object');
isa_ok($person, 'URT::Person');
is($person->name, 'Joe', 'Got the right person');
is($person->job_name, 'cleaner', 'With the right job name');
is ($person->job_phone, '456-789-0123', 'the right job_phone');
is ($person->work_phone, '456-789-0123', 'and the right work_phone');

# This one wasn't working before I fixed UR::Object::Property::_get_joins()
$person = URT::Person->get(work_phone => '123-456-7890');

ok($person, 'get() returned an object');
isa_ok($person, 'URT::Person');
is($person->name, 'Bob', 'Got the right person');
is($person->job_name, 'cook', 'With the right job name');
is($person->job_phone, '123-456-7890', 'the right job_phone');
is($person->work_phone, '123-456-7890', 'and the right work_phone');


sub setup_classes_and_db {
    my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

    ok($dbh, 'Got DB handle');

    ok( $dbh->do("create table locations (location_id integer, phone_number varchar, address varchar)"),
       'Created locations table');

    ok( $dbh->do("create table jobs (job_id integer, job_name varchar, location_id integer REFERENCES locations(location_id))"),
       'Created jobs table');

    ok( $dbh->do("create table persons (person_id integer, name varchar, job_id integer REFERENCES jobs(job_id))"),
       'Created persons table');

    # First person 
    $dbh->do("insert into locations (location_id, phone_number, address) values (1,'123-456-7890','123 Fake St')");
    $dbh->do("insert into jobs (job_id, job_name, location_id) values (1, 'cook', 1)");
    $dbh->do("insert into persons (person_id, name, job_id) values(1,'Bob', 1)");

    # second
    $dbh->do("insert into locations (location_id, phone_number, address) values (2,'456-789-0123','987 Main St')");
    $dbh->do("insert into jobs (job_id, job_name, location_id) values (2, 'cleaner', 2)");
    $dbh->do("insert into persons (person_id, name, job_id) values(2,'Joe', 2)");

    ok($dbh->commit(), 'DB commit');
           
    UR::Object::Type->define(
        class_name => 'URT::Location',
        id_by => [
            location_id => { is => 'Integer' },
        ],
        has => [
            phone_number => { is => 'String' },
            address      => { is => 'String' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'locations',
    );

    UR::Object::Type->define(
        class_name => 'URT::Job',
        id_by => [
            job_id => { is => 'Integer' },
        ],
        has => [
            job_name => { is => 'String' },
            location => { is => 'URT::Location', id_by => 'location_id' },
            location_phone => { via => 'location', to => 'phone_number' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'jobs',
    );

    UR::Object::Type->define(
        class_name => 'URT::Person',
        id_by => [
            person_id => { is => 'Integer' },
        ],
        has => [
            name   => { is => 'String' },

            job_id   => { is => 'Integer' },
            job      => { is => 'URT::Job', id_by => 'job_id' },
            job_name => { via => 'job' },
            job_phone => { via => 'job', to => 'location_phone' },

            work_location_id => { via => 'job', to => 'location_id' },
            work_location    => { is => 'URT::Location', id_by => 'work_location_id' },
            work_phone       => { via => 'work_location', to => 'phone_number' },
        ],
        data_source => 'URT::DataSource::SomeSQLite',
        table_name => 'persons',
    );
}

