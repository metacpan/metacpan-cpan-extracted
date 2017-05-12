package UR::Namespace::Command::Define::Datasource::Mysql;

use strict;
use warnings;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Define::Datasource::RdbmsWithAuth",
);

sub help_brief {
   "Add a MySQL data source to the current namespace."
}

sub _data_source_sub_class_name {
    'UR::DataSource::MySQL'
}

1;

