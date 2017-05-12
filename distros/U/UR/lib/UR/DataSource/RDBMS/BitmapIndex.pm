use strict;
use warnings;

package UR::DataSource::RDBMS::BitmapIndex;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::BitmapIndex',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_bitmap_index',
    er_role => '',
    id_properties => [qw/data_source table_name bitmap_index_name/],
    properties => [
        bitmap_index_name                => { type => 'varchar', len => undef, sql => 'bitmap_index_name' },
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'},
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        owner                            => { type => 'varchar', len => undef, is_optional => 1, sql => 'owner' },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
    ],
    data_source => 'UR::DataSource::Meta',
);

1;

=pod

=head1 NAME

UR::DataSource::RDBMS::BitmapIndex - metadata about a data source's bitmap indexes

=head1 DESCRIPTION

This class represents instances of bitmap indexes in a data source.  They are
maintained by 'ur update classes' and stored in the namespace's MetaDB.

The existence of bitmap indexes in a datasource affects SQL generation during
a Context commit.  Oracle's implementation requires a table covered by a
bitmap index to be locked while it is being updated.

=cut
