# This documents a bug in a prior implementation of RDBMSRetriableOperations's
# rdbms_datasource_method_for that would get stuck in an infinite loop if there
# were any intermediate classes in the inheritance between the actual data
# source and the inheritance of RDBMSRetriableOperations.

use strict;
use warnings;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;


package URT::DataSource::RetriableSQLite;
class URT::DataSource::RetriableSQLite {
    is => [
        'UR::DataSource::RDBMSRetriableOperations',
        'URT::DataSource::SomeSQLite',
    ],
};


package URT::DataSource::RetryDBWithoutOverride;
class URT::DataSource::RetryDBWithoutOverride {
    is => 'URT::DataSource::RetriableSQLite',
    doc => 'no _sync_database override',
};


package URT::DataSource::RetryDBWithOverride;
class URT::DataSource::RetryDBWithOverride {
    is => 'URT::DataSource::RetriableSQLite',
    doc => 'with _sync_database override',
};

sub _sync_database {
    my $self = shift;
    $self->SUPER::_sync_database(@_);
}


package main;

use Test::More tests => 2;

for my $ds_name (qw(
    URT::DataSource::RetryDBWithOverride
    URT::DataSource::RetryDBWithoutOverride
)) {
    my $ds = $ds_name->get();
    my $sync_rv = $ds->_sync_database();
    ok($sync_rv, "$ds_name: _sync_database returned successfully");
}
