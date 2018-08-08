package UR::DataSource::RDBMS::Table::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
    has_many => [
        default_aspects => { is => 'ARRAY', is_constant => 1, value => ['table_name', 'data_source', 'column_names'] },
    ],
);


1;

=pod

=head1 NAME

UR::DataSource::RDBMS::Table::View::Default::Text - View class for RDBMS table objects

=head1 DESCRIPTION

This class defines a text-mode view for RDBMS table objects, and is used by
the 'ur info' command.

=cut
