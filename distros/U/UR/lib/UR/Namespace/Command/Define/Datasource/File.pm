package UR::Namespace::Command::Define::Datasource::File;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

use IO::File;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::Define::Datasource',
    has => [
        server => {
            is => 'String',
            doc => '"server" attribute for this data source, such as a database name',
        },
        singleton => {
            is => 'Boolean',
            default_value => 1,
            doc => 'by default all data sources are singletons, but this can be turned off' 
        },
    ],
    doc => 'Add a file-based data source (not yet implemented)'
);

sub help_description {
   "Define a UR datasource connected to a file";
}

sub execute {
    my $self = shift;

    $self->warning_message("This command is not yet implemented.  See the documentation for UR::DataSource::File for more information about creating file-based data sources");
    return;
}

1;

