use strict;
use warnings;

package UR::DataSource::RDBMS::FkConstraintColumn;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::FkConstraintColumn',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_fk_constraint_column',
    er_role => 'bridge',
    id_properties => [qw/data_source table_name fk_constraint_name column_name/],
    properties => [
        column_name                      => { type => 'varchar', len => undef, sql => 'column_name' },
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'},
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        fk_constraint_name               => { type => 'varchar', len => undef, sql => 'fk_constraint_name' },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
        r_column_name                    => { type => 'varchar', len => undef, sql => 'r_column_name' },
        r_table_name                     => { type => 'varchar', len => undef, sql => 'r_table_name' },
    ],
    data_source => 'UR::DataSource::Meta',
);

1;

=pod

=head1 NAME 

UR::DataSource::RDBMS::FkConstraintColumn - metadata about a data source's foreign keys

=head1 DESCRIPTION

This class represents the column linkages that make up a foreign key.  Each
instance has a column_name (the source, where the foreign key points from)
and r_column_name (remote column name, where the fireign key points to),
as well as the source and remote table names.

=cut


