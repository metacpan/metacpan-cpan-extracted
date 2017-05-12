use strict;
use warnings;

package UR::DataSource::RDBMS::TableColumn;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::TableColumn',
    is => ['UR::DataSource::RDBMS::Entity'],
    dsmap => 'dd_table_column',
    er_role => '',
    id_properties => [qw/data_source table_name column_name/],
    properties => [
        column_name                      => { type => 'varchar', len => undef, sql => 'column_name' },
        data_source                      => { type => 'varchar', len => undef, sql => 'data_source' },
        data_source_obj                  => { type => 'UR::DataSource', id_by => 'data_source'},
        namespace                        => { calculate_from => [ 'data_source'],
                                              calculate => q( (split(/::/,$data_source))[0] ) },
        owner                            => { type => 'varchar', len => undef, is_optional => 1, sql => 'owner' },
        table_name                       => { type => 'varchar', len => undef, sql => 'table_name' },
        data_length                      => { type => 'varchar', len => undef, is_optional => 1, sql => 'data_length' },
        data_type                        => { type => 'varchar', len => undef, sql => 'data_type' },
        last_object_revision             => { type => 'timestamp', len => undef, sql => 'last_object_revision' },
        nullable                         => { type => 'varchar', len => undef, sql => 'nullable' },
        remarks                          => { type => 'varchar', len => undef, is_optional => 1, sql => 'remarks' },
    ],
    data_source => 'UR::DataSource::Meta',
);

# Methods moved over from the old App::DB::TableColumn

sub _fk_constraint_class {
    my $self = shift;

    if (ref($self) =~ /::Ghost$/) {
        return "UR::DataSource::RDBMS::FkConstraint::Ghost"
    }
    else {
        return "UR::DataSource::RDBMS::FkConstraint"
    }
}

sub get_table {
    my $self = shift;

    my $table_name = $self->table_name;
    my $data_source = $self->data_source;
    $data_source or Carp::confess("Can't determine data_source for table $table_name column ".$self->column_name );
    my $table =
        UR::DataSource::RDBMS::Table->get(table_name => $table_name, data_source => $data_source)
        ||
        UR::DataSource::RDBMS::Table::Ghost->get(table_name => $table_name, data_source => $data_source);
    return $table;
}


sub fk_constraint_names {

    my @fks = shift->fk_constraints;
    return map { $_->fk_constraint_name } @fks;
}


sub fk_constraints {
    my $self = shift;

    my $fk_class = $self->_fk_constraint_class();
    my @fks = $fk_class->get(table_name => $self->table_name,
                             data_source => $self->data_source);
                       
    return @fks;
}


sub bitmap_index_names {
Carp::confess("not implemented yet?!");
}


# the update classes code uses this.  If the data type of a column is a time-ish format, then
# the data_length reported by the schema is the number of bytes used internally by the DB.
# Since the UR-object will store the time in text format, it will always be longer than
# that.  To keep $obj->__errors__ from complaining, don't even bother storing the length of
# time-ish data
sub is_time_data {
    my $self = shift;

    my $type = $self->data_type;
    if ($type =~ m/TIMESTAMP|DATE|INTERVAL/i) {
        return 1;
    } else {
        return;
    }
}

1;

=pod

=head1 NAME

UR::DataSource::RDBMS::TableColumn - metadata about a data source's table's columns

=head1 DESCRIPTION

This class represents instances of columns in a data source's tables.  They are
maintained by 'ur update classes' and stored in the namespace's MetaDB.

=cut

