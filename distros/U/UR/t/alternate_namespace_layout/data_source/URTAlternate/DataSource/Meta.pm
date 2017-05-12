package URTAlternate::DataSource::Meta;

# The datasource for metadata describing the tables, columns and foreign
# keys in the target datasource

use strict;
use warnings;

use UR;

UR::Object::Type->define(
    class_name => 'URTAlternate::DataSource::Meta',
    is => ['UR::DataSource::Meta'],
);

use File::Temp;

# Override server() so we can make the metaDB file in
# a temp dir

sub server {
    my $self = shift;

    our $PATH;
    $PATH ||= File::Temp::tmpnam() . "_ur_testsuite_metadb" . $self->_extension_for_db;
    return $PATH;
}

END {
    our $PATH;
    unlink $PATH if ($PATH);
}

    

1;
