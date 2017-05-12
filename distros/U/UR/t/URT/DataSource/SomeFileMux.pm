
package URT::DataSource::SomeFileMux;
use strict;
use warnings;

use UR::Object::Type;
use URT;

use File::Temp qw();

class URT::DataSource::SomeFileMux {
    is => ['UR::DataSource::FileMux', 'UR::Singleton'],
};

sub constant_values { [ 'thing_type' ] }

sub required_for_get { [ 'thing_type' ] }

sub column_order {
    return [ qw( thing_id thing_name thing_color )];
}

sub sort_order {
    return ['thing_id' ] ;
}

sub delimiter { "\t" }

BEGIN {
    our $BASE_PATH = File::Temp::tempdir( CLEANUP => 1 );
}

# Note that the file resolver is called as a normal function (with the parameters
# mentioned in requiret_for_get), not as a method with the data source as the
# first arg...
sub file_resolver {
    my $type = shift;
    our $BASE_PATH;
    return "$BASE_PATH/$type";
}

1;
