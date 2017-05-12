# This documents a bug that didn't actually get shipped that would cause the
# default retriable methods on RDBMSRetriableOperations to wrap the first data
# source to use it even for subsequent data sources.

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

use Test::More tests => 8;

my %_sync_database;
*URT::DataSource::SomeSQLiteA::_sync_database = sub {
    $_sync_database{'URT::DataSource::SomeSQLiteA'}++;
    return 1;
};
*URT::DataSource::SomeSQLiteB::_sync_database = sub {
    $_sync_database{'URT::DataSource::SomeSQLiteB'}++;
    return 1;
};

my @ds_spec = (
    ['URT::DataSource::SomeSQLiteA', 'URT::DataSource::RetriableSQLiteA'],
    ['URT::DataSource::SomeSQLiteB', 'URT::DataSource::RetriableSQLiteB'],
);

my $method = '_sync_database';

for (my $i = 0; $i < @ds_spec; $i++) {
    my $ds_typename = $ds_spec[$i][0];
    my $ds_name     = $ds_spec[$i][1];

    UR::Object::Type->define(
        class_name => $ds_typename,
        is => 'URT::DataSource::SomeSQLite',
    );

    UR::Object::Type->define(
        class_name => $ds_name,
        is => [
            'UR::DataSource::RDBMSRetriableOperations',
            $ds_typename,
        ],
    );
}

for (my $i = 0; $i < @ds_spec; $i++) {
    my $ds_typename = $ds_spec[$i][0];
    my $ds_name     = $ds_spec[$i][1];

    my $oi = ($i + 1) % 2;
    my $other_ds_typename = $ds_spec[$oi][0];
    my $other_ds_name     = $ds_spec[$oi][1];

    setUp();
    is(scalar(keys %_sync_database), 0, "$ds_name: setUp OK");

    my $ds = $ds_name->get();
    my $sync_rv = $ds->$method();

    ok($sync_rv,                             "$ds_name: $method returned successfully");
    ok( $_sync_database{$ds_typename},       "$ds_name: this datasource method was called");
    ok(!$_sync_database{$other_ds_typename}, "$ds_name: other datasource method was not called");
}

sub setUp {
    for my $k (keys %_sync_database) {
        delete $_sync_database{$k};
    }
}
