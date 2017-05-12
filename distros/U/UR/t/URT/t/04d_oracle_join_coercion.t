#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 20;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use URT; # dummy namespace

# This tests the Oracle data source's ability to join a text-type column
# to a non-text type, like a number or date.  Oracle versions 10 and under
# seemed to be more permissive when joining dissimilar columns.  Version
# 11 rejects queries that worked before.
#
# Make a few classes that can join to each other, numbers and text

UR::Object::Type->define(
    class_name => 'URT::A',
    id_by => [
        a_id => { is => 'String' },
    ],
    has => [
        age => { is => 'Number' },

        b_id => { is => 'Number' },
        b => { is => 'URT::B', id_by => 'b_id' },
        b_name => { via => 'b', to => 'name' },
    ],
    table_name => 'A',
    data_source => 'URT::DataSource::SomeOracle',
);

UR::Object::Type->define(
    class_name => 'URT::AChild',
    is => 'URT::A',
    id_by => [
        a_id => { is => 'Number' },
    ],
    table_name => 'A_CHILD',
    data_source => 'URT::DataSource::SomeOracle',
);

UR::Object::Type->define(
    class_name => 'URT::B',
    id_by => [
        b_id => { is => 'String' },
    ],
    has => [
        a_id => { is => 'String' },
        a_child => { is => 'URT::AChild', id_by => 'a_id' },

        name => { is => 'String' },
    ],
    table_name => 'B',
    data_source => 'URT::DataSource::SomeOracle',
);


my $sql = '';
URT::DataSource::SomeOracle->add_observer(
    aspect => 'query',
    callback => sub {
        my $ds = shift;
        my $aspect = shift;
        $sql = shift;
        $sql =~ s/\n/ /g;       # Convert newlines to spaces
        $sql =~ s/^\s+|\s+$//g; # Remove leading and trailing whitespace

        # We need to die here so it dosen't try to connect to this
        # fake oracle database, which happens right after the SQL is
        # constructed
        die "escape\n";
    }
);

# URT::A and URT::AChild, when joined, will have the to_char
# coercion on the left.  Joining to B will also have the coercion
# on the left
$sql = '';
eval { URT::AChild->get(1) };
like($@, qr(escape), 'Query on AChild');
is($sql,
    q{select A_CHILD.a_id, A.a_id, A.age, A.b_id from A_CHILD INNER join A on to_char(A_CHILD.a_id) = A.a_id where A_CHILD.a_id = ? order by A_CHILD.a_id},
    "to_char coercion on A_CHILD's ID column for inheritance on the left");

$sql = '';
eval { URT::A->get(b_name => 'foo') };
like($@, qr(escape), 'Query on A, filter by b_name');
is($sql,
    q{select A.a_id, A.age, A.b_id, b_name_1.a_id, b_name_1.b_id, b_name_1.name from A LEFT join B b_name_1 on to_char(A.b_id) = b_name_1.b_id where b_name_1.name = ? order by A.a_id},
    "to_char coercion for A's B_ID column for via/to on the left");

$sql = '';
eval { URT::AChild->get(b_name => 'foo') };
like($@, qr(escape), 'Query on A, filter by b_name');
is($sql,
    q{select A_CHILD.a_id, A.a_id, A.age, A.b_id, b_name_1.a_id, b_name_1.b_id, b_name_1.name from A_CHILD INNER join A on to_char(A_CHILD.a_id) = A.a_id LEFT join B b_name_1 on to_char(A.b_id) = b_name_1.b_id where b_name_1.name = ? order by A_CHILD.a_id},
    "to_char coercion on A_CHILD's ID column and A's B_ID column are both on the left");

$sql = '';
eval { URT::B->get('a_child.age' => 'foo') };
like($@, qr(escape), 'Query on B, filter by a_child.age');
is($sql,
    q{select B.a_id, B.b_id, B.name, a_child_age_1.a_id, a_child_age_2.a_id, a_child_age_2.age, a_child_age_2.b_id from B LEFT join A_CHILD a_child_age_1 on B.a_id = to_char(a_child_age_1.a_id) LEFT join A a_child_age_2 on to_char(a_child_age_1.a_id) = a_child_age_2.a_id where a_child_age_2.age = ? order by B.b_id},
    "to_char coercion on B's a_id column for via/to on the right, and A_CHILD's inheritance on the left");

$sql = '';
# Kind of a nonsense query... will join through A_CHILD, A and back to B
eval { URT::B->get('a_child.b.name' => 'foo') };
like($@, qr(escape), 'Query on B, filter by a_child.b.name');
is($sql,
    q{select B.a_id, B.b_id, B.name, a_child_b_name_1.a_id, a_child_b_name_2.a_id, a_child_b_name_2.age, a_child_b_name_2.b_id, a_child_b_name_3.a_id, a_child_b_name_3.b_id, a_child_b_name_3.name from B LEFT join A_CHILD a_child_b_name_1 on B.a_id = to_char(a_child_b_name_1.a_id) LEFT join A a_child_b_name_2 on to_char(a_child_b_name_1.a_id) = a_child_b_name_2.a_id LEFT join B a_child_b_name_3 on to_char(a_child_b_name_2.b_id) = a_child_b_name_3.b_id where a_child_b_name_3.name = ? order by B.b_id},
    "to_char coerction on the right for B's via/to A, and left for A_CHILD's inheritance and A's via/to B");


UR::Object::Type->define(
    class_name => 'URT::Activity',
    id_by => [
        date => { is => 'DateTime' },
    ],
    has => [
        description => { is => 'String' },
    ],
    has_many => [
        bridges => { is => 'URT::ThingActivityBridge', reverse_as => 'activity' },
        things => { is => 'URT::Thing', via => 'bridges', to => 'thing' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'ACTIVITY',
);

UR::Object::Type->define(
    class_name => 'URT::Thing',
    id_by => [
        thing_id => { is => 'Number' },
    ],
    has => [
        name            => { is => 'String' },
        latest_date     => { is => 'String' },
        latest_activity => { is => 'URT::Activity', id_by => 'latest_date' },
        latest_activity_description => { via => 'latest_activity', to => 'description' },
    ],
    has_many => [
        bridges         => { is => 'URT::ThingActivityBridge', reverse_as => 'thing' },
        activities      => { is => 'URT::Activity', via => 'bridges', to => 'activity' },
        activity_descriptions => { via => 'activities', to => 'description' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'THING',
);

UR::Object::Type->define(
    class_name => 'URT::ThingActivityBridge',
    id_by => [
        thing_id => { is => 'String' },
        date => { is => 'String' },
    ],
    has => [
        thing => { is => 'URT::Thing', id_by => 'thing_id' },
        activity => { is => 'URT::Activity', id_by => 'date' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'BRIDGE',
);

$sql = '';
eval { URT::Thing->get(-hints => ['latest_activity_description']) };
like($@, qr(escape), 'Query on Thing, -hint on latest_activity_description');
is($sql,
    q{select THING.latest_date, THING.name, THING.thing_id, latest_activity_description_1.date, latest_activity_description_1.description from THING LEFT join ACTIVITY latest_activity_description_1 on THING.latest_date = to_char(latest_activity_description_1.date, 'YYYY-MM-DD HH24:MI:SS') order by THING.thing_id},
    "to_char coercion used when joining ACTIVITY's date column to THING's latest_date column");


$sql = '';
eval { URT::Thing->get('activity_descriptions like' => '%cool%') };
like($@, qr(escape), 'Query on Thing, filter on activity_descriptions like %cool%');
is($sql,
    q{select THING.latest_date, THING.name, THING.thing_id, bridges_1.date, bridges_1.thing_id, activity_descriptions_2.date, activity_descriptions_2.description from THING LEFT join BRIDGE bridges_1 on to_char(THING.thing_id) = bridges_1.thing_id LEFT join ACTIVITY activity_descriptions_2 on bridges_1.date = to_char(activity_descriptions_2.date, 'YYYY-MM-DD HH24:MI:SS') where activity_descriptions_2.description like ? escape '\' order by THING.thing_id},
    "to_char coercion present joining THING to BRIDGE by thing_id, and joining BRIDGE to ACTIVITY by date");


# These are the same classes as immediatly above, but URT::Activity2::date is a Timestamp
# instead of DateTime
UR::Object::Type->define(
    class_name => 'URT::Activity2',
    id_by => [
        date => { is => 'Timestamp' },
    ],
    has => [
        description => { is => 'String' },
    ],
    has_many => [
        bridges => { is => 'URT::ThingActivityBridge2', reverse_as => 'activity' },
        things => { is => 'URT::Thing2', via => 'bridges', to => 'thing' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'ACTIVITY',
);

UR::Object::Type->define(
    class_name => 'URT::Thing2',
    id_by => [
        thing_id => { is => 'Number' },
    ],
    has => [
        name            => { is => 'String' },
        latest_date     => { is => 'String' },
        latest_activity => { is => 'URT::Activity2', id_by => 'latest_date' },
        latest_activity_description => { via => 'latest_activity', to => 'description' },
    ],
    has_many => [
        bridges         => { is => 'URT::ThingActivityBridge2', reverse_as => 'thing' },
        activities      => { is => 'URT::Activity2', via => 'bridges', to => 'activity' },
        activity_descriptions => { via => 'activities', to => 'description' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'THING',
);

UR::Object::Type->define(
    class_name => 'URT::ThingActivityBridge2',
    id_by => [
        thing_id => { is => 'String' },
        date => { is => 'String' },
    ],
    has => [
        thing => { is => 'URT::Thing2', id_by => 'thing_id' },
        activity => { is => 'URT::Activity2', id_by => 'date' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'BRIDGE',
);


$sql = '';
eval { URT::Thing2->get(-hints => ['latest_activity_description']) };
like($@, qr(escape), 'Query on Thing, -hint on latest_activity_description');
is($sql,
    q{select THING.latest_date, THING.name, THING.thing_id, latest_activity_description_1.date, latest_activity_description_1.description from THING LEFT join ACTIVITY latest_activity_description_1 on THING.latest_date = to_char(latest_activity_description_1.date, 'YYYY-MM-DD HH24:MI:SSXFF') order by THING.thing_id},
    "to_char coercion used when joining ACTIVITY's date column to THING's latest_date column");


$sql = '';
eval { URT::Thing2->get('activity_descriptions like' => '%cool%') };
like($@, qr(escape), 'Query on Thing, filter on activity_descriptions like %cool%');
is($sql,
    q{select THING.latest_date, THING.name, THING.thing_id, bridges_1.date, bridges_1.thing_id, activity_descriptions_2.date, activity_descriptions_2.description from THING LEFT join BRIDGE bridges_1 on to_char(THING.thing_id) = bridges_1.thing_id LEFT join ACTIVITY activity_descriptions_2 on bridges_1.date = to_char(activity_descriptions_2.date, 'YYYY-MM-DD HH24:MI:SSXFF') where activity_descriptions_2.description like ? escape '\' order by THING.thing_id},
    "to_char coercion present joining THING to BRIDGE by thing_id, and joining BRIDGE to ACTIVITY by date");


# Test a join where the get() target and the class it joins to do not
# have tables, but their parent do.  Also, the joined columns have different names
UR::Object::Type->define(
    class_name => 'URT::LinkParent',
    id_by => [
        id => { is => 'Integer' },
    ],
    has => [
        name => { is => 'String' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'LINK',
);
UR::Object::Type->define(
    class_name => 'URT::Link',
    is => 'URT::LinkParent'
);
UR::Object::Type->define(
    class_name => 'URT::AbstractParent',
    id_by => [
        parent_id => { is => 'String' },
    ],
    has => [
        link_id => { is => 'String' },
        link => { is => 'URT::Parent', id_by => 'link_id' },
        link_name => { via => 'link', to => 'name' },
    ],
    data_source => 'URT::DataSource::SomeOracle',
    table_name => 'ABSTRACT_PARENT',
);
UR::Object::Type->define(
    class_name => 'URT::Concrete',
    is => 'URT::AbstractParent',
    has => [
        # Child overrides parent property with more specific 'is'
        link => { is => 'URT::Link', id_by => 'link_id' },
        something => { is => 'String' }
    ]
);

$sql = '';
eval { URT::Concrete->get(-hints => ['link']) };
like($@, qr(escape), 'Query on Thing, filter on activity_descriptions like %cool%');
is($sql,
    q(select ABSTRACT_PARENT.link_id, ABSTRACT_PARENT.parent_id, link_2.id, link_2.name from ABSTRACT_PARENT LEFT join LINK link_2 on ABSTRACT_PARENT.link_id = to_char(link_2.id) order by ABSTRACT_PARENT.parent_id),
    'to_char conversion and correct column linking when joining child classes that do not have tables');



1;
