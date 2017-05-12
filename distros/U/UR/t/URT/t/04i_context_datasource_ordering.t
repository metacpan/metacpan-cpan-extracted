#!/usr/bin/env perl

use strict;
use warnings;

use constant NUM_TESTS => 5;

use Test::More tests => NUM_TESTS;
use Test::Exception;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";

use List::Util qw(shuffle);

use URT; # dummy namespace

my @data_sources = map { $_->get() } qw(UR::DataSource::Default URT::DataSource::SomeSQLite URT::DataSource::SomeFile URT::DataSource::SomeOracle);

#Default DataSource must be last
#Oracle can_savepoint, so its DataSource should come after the others
#Other DataSources should be sorted on name
my @expected_order = @data_sources[2,1,3,0];

for (1..NUM_TESTS) {
    my @ordered_data_sources = UR::Context::_order_data_sources_for_saving(shuffle @data_sources);
    is_deeply(\@ordered_data_sources, \@expected_order, 'datasources are ordered as expected');
}
