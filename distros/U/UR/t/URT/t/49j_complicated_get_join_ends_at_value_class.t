#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use URT::DataSource::SomeSQLite;
use Test::More tests => 9;


# tests a get() where the a UR::Value-related property is in the hints list, but
# in order to satisfy that hint, it needs to join to the attribute table to retrieve
# the Value's ID
#
# Before the fix, the QueryPlan had a couple of issues
# 1) The delegated properties loop would remove all joins through UR::Value classes,
#    leaving the @join list empty.  At the snd of the delegation loop,
#    $last_class_object_excluding_inherited_joins had not been set, and so it dies
# 2) UR::Object::Join::resolve_forward() would not recursivly find and joins required
#    to fulfill the id_by property.

my $dbh = URT::DataSource::SomeSQLite->get_default_handle;

$dbh->do('create table disk (disk_id integer not null primary key, name varchar not null)');
$dbh->do('create table attribute (attr_id integer not null primary key, disk_id integer references disk(disk_id), key varchar, value varchar)');

$dbh->do("insert into disk values (1,'boot')");
$dbh->do("insert into attribute values (3,1,'size_bytes', 2097152)");   # 2048K

UR::Object::Type->define(
    class_name => 'Disk::Value::KBytes',
    is => 'UR::Value',
);

sub Disk::Value::KBytes::__display_name__ {
    my $size = shift->id;
    my $kbytes = $size / 1024;
    return $kbytes."K";
}

UR::Object::Type->define(
    class_name => 'Disk',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'disk',
    id_by => [
        disk_id => { is => 'Integer' },
    ],
    has => [
       name => { is => 'String', },
       attributes => { is => 'Attribute', reverse_as => 'disk', is_many => 1 },
       size => { via => 'attributes', to => 'value', where => [key => 'size_bytes'] },
       pretty_size_kbytes => { is => 'Disk::Value::KBytes', id_by => 'size' },
    ],
);

UR::Object::Type->define(
    class_name => 'Attribute',
    data_source => 'URT::DataSource::SomeSQLite',
    table_name => 'attribute',
    id_by => [
        attr_id => { is => 'Integer' },
    ],
    has => [
        disk => { is => 'Disk', id_by => 'disk_id' },
        key => { is => 'String', },
        value => { is => 'String', },
    ],
);


my $query_count = 0;
ok(URT::DataSource::SomeSQLite->create_subscription(
                    method => 'query',
                    callback => sub { $query_count++ }),
   'Created a subscription for query');
my @d = Disk->get(-hints => ['pretty_size_kbytes']);
is(scalar(@d), 1, 'Got the object');
is($query_count, 1, 'Made one query');

$query_count = 0;
my $value_obj = $d[0]->pretty_size_kbytes;
ok($value_obj, 'Got the value object for size');
is($query_count, 0, 'Made no queries');

$query_count = 0;
is($value_obj->id, $d[0]->size, 'The ID of the value object matches the original object size');
is($query_count, 0, 'Made no queries');

$query_count = 0;
is($value_obj->__display_name__, "2048K", '__display_name__ for Value object is correct');
is($query_count, 0, 'Made no queries');
