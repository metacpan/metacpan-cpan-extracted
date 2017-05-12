#!/usr/bin/env perl
use strict;
use warnings;
use Test::More skip_all => "enable after configuring Oracle";

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

my $dbh = URT::DataSource::SomeOracle->get_default_handle;
ok($dbh, "got a handle");
isa_ok($dbh, 'UR::DBI::db', 'Returned handle is the proper class');


1;
