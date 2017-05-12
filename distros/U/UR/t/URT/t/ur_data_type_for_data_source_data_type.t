use strict;
use warnings;

use Test::More tests => 2;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../..";
use URT;

my $uc_dt    = URT::DataSource::SomeOracle->ur_data_type_for_data_source_data_type('TIMESTAMP');
my $ps_dt  = URT::DataSource::SomeOracle->ur_data_type_for_data_source_data_type('TIMESTAMP(9)');
my $lc_dt = URT::DataSource::SomeOracle->ur_data_type_for_data_source_data_type('timestamp');
is($ps_dt, $uc_dt, 'data type with paren suffix matches upper case result');
is($lc_dt, $uc_dt, 'lower case data type matches upper case result');
