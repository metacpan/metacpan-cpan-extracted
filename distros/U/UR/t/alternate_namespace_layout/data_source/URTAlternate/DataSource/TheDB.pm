package URTAlternate::DataSource::TheDB;
use strict;
use warnings;

use File::Temp;

use URTAlternate;
class URTAlternate::DataSource::TheDB {
    is => ['UR::DataSource::SQLite'],
};

sub server {
    my $self = shift;

    our $PATH;
    $PATH ||= File::Temp::tmpnam() . '_ur_testsuite_db' . $self->_extension_for_db;
    return $PATH;
}

END {
    our $PATH;
    unlink $PATH if $PATH;
}

1;
