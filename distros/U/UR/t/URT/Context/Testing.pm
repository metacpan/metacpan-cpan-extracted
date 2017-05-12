package URT::Context::Testing;
use strict;
use warnings;

use UR::Object::Type;

use URT;
class URT::Context::Testing {
    is => ['UR::Context::Root'],
    doc => 'Used by the automated test suite.',
};

sub get_default_data_source {
    "GSC::DataSource::SomeSQLite"
}

1;
#$Header
