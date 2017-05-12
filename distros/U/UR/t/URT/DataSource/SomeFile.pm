package URT::DataSource::SomeFile;
use strict;
use warnings;

use URT;
use File::Temp qw();

our(undef, $FILE) = File::Temp::tempfile();
END { unlink $FILE };

class URT::DataSource::SomeFile {
    is => ['UR::Singleton', 'UR::DataSource::File'],
};

sub server { $FILE }

sub column_order {
    return [ qw( thing_id thing_name thing_color ) ];
}

sub sort_order {
    return ['thing_id'];
}

sub delimiter { "\t" }


1;
