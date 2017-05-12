use strict;
use warnings;

package UR::DataSource::RDBMS::UniqueConstraintColumn;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::UniqueConstraintColumn',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_unique_constraint_column',
    id_properties => [qw/data_source table_name constraint_name column_name/],
    properties => [
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'},
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        owner                            => { type => 'varchar', len => undef, sql => 'owner', is_optional => 1 },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
        constraint_name                  => { type => 'varchar', len => undef, sql => 'constraint_name' },
        column_name                      => { type => 'varchar', len => undef, sql => 'column_name' },
    ],
    data_source => 'UR::DataSource::Meta',
);

1;


=pod

=head1 NAME

UR::DataSource::RDBMS::UniqueConstraintColumn - metadata about a data source's unique constraints

=head1 DESCRIPTION

This class represents instances of unique constraints in a data source.  They are
maintained by 'ur update classes' and stored in the namespace's MetaDB.

Multi-column unique constraints are represented by instances having the same
table_name and constraint_name, but different column_names.

=cut

