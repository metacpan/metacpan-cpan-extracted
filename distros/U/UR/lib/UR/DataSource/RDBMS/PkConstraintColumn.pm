use strict;
use warnings;

package UR::DataSource::RDBMS::PkConstraintColumn;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::PkConstraintColumn',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_pk_constraint_column',
    er_role => '',
    id_properties => [qw/data_source table_name column_name rank/],
    properties => [
        column_name                      => { type => 'varchar', len => undef, sql => 'column_name' },
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'},
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        owner                            => { type => 'varchar', len => undef, is_optional => 1, sql => 'owner' },
        rank                             => { type => 'integer', len => undef, sql => 'rank' },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
    ],
    data_source => 'UR::DataSource::Meta',
);

1;

=pod

=head1 NAME

UR::DataSource::RDBMS::PkConstraintColumn - metadata about a data source's primary keys

=head1 DESCRIPTION

This class represents columns that make up a primary key.  Tables with
multiple-column primary keys are ordered by their 'rank' property.

=cut
