package UR::DataSource::RDBMS::TableColumn::View::Default::Text;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Object::View::Default::Text',
    has => [
        default_aspects => { is => 'ARRAY', is_constant => 1, value => ['column_name', 'table_name', 'data_type', 'length', 'nullable'] },
    ],
);


1;

=pod

=head1 NAME

UR::DataSource::RDBMS::TableColumn::View::Default::Text - View class for RDBMS column objects

=head1 DESCRIPTION

This class defines a text-mode view for RDBMS column objects, and is used by
the 'ur info' command.

=cut

