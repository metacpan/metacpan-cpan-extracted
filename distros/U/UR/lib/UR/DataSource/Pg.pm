package UR::DataSource::Pg;
use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::Pg',
    is => ['UR::DataSource::RDBMS'],
    is_abstract => 1,
);

# RDBMS API

sub driver { "Pg" }

#sub server {
#    my $self = shift->_singleton_object();
#    $self->_init_database;
#    return $self->_database_file_path;
#}

sub owner { shift->_singleton_object->login }

#sub login {
#    undef
#}
#
#sub auth {
#    undef
#}

sub _default_sql_like_escape_string { return '\\\\' };

sub _format_sql_like_escape_string {
    my $class = shift;
    my $escape = shift;
    return "E'$escape'";
}

sub can_savepoint { 1;}

sub set_savepoint {
my($self,$sp_name) = @_;

    my $dbh = $self->get_default_handle;
    $dbh->pg_savepoint($sp_name);
}

sub rollback_to_savepoint {
my($self,$sp_name) = @_;

    my $dbh = $self->get_default_handle;
    $dbh->pg_rollback_to($sp_name);
}


*_init_created_dbh = \&init_created_handle;
sub init_created_handle
{
    my ($self, $dbh) = @_;
    return unless defined $dbh;
    $dbh->{LongTruncOk} = 0;
    return $dbh;
}

sub _ignore_table {
    my $self = shift;
    my $table_name = shift;
    return 1 if $table_name =~ /^(pg_|sql_)/;
}


sub _get_next_value_from_sequence {
my($self,$sequence_name) = @_;

    # we may need to change how this db handle is gotten
    my $dbh = $self->get_default_handle;
    my($new_id) = $dbh->selectrow_array("SELECT nextval('$sequence_name')");

    if ($dbh->err) {
        die "Failed to prepare SQL to generate a column id from sequence: $sequence_name.\n" . $dbh->errstr . "\n";
        return;
    }

    return $new_id;
}

# The default for PostgreSQL's serial datatype is to create a sequence called
# tablename_columnname_seq
sub _get_sequence_name_for_table_and_column {
my($self,$table_name, $column_name) = @_;
    return sprintf("%s_%s_seq",$table_name, $column_name);
}


sub get_bitmap_index_details_from_data_dictionary {
    # FIXME Postgres has bitmap indexes, but we don't support them yet.  See the Oracle
    # datasource module for details about how to get it working
    return [];
}


sub get_unique_index_details_from_data_dictionary {
    my($self, $owner_name, $table_name) = @_;

    my $sql = qq(
        SELECT c_index.relname, a.attname
        FROM pg_catalog.pg_class c_table
        JOIN pg_catalog.pg_index i ON i.indrelid = c_table.oid
        JOIN pg_catalog.pg_class c_index ON c_index.oid = i.indexrelid
        JOIN pg_catalog.pg_attribute a ON a.attrelid = c_index.oid
        JOIN pg_catalog.pg_namespace n ON c_table.relnamespace = n.oid
        WHERE c_table.relname = ? AND n.nspname = ?
          and (i.indisunique = 't' or i.indisprimary = 't')
          and i.indisvalid = 't'
    );
    
    my $dbh = $self->get_default_handle();
    return undef unless $dbh;

    my $sth = $dbh->prepare($sql);
    return undef unless $sth;

    #my $db_owner = $self->owner();  # We should probably do something with the owner/schema
    $sth->execute($table_name, $owner_name);

    my $ret;
    while (my $data = $sth->fetchrow_hashref()) {
        $ret->{$data->{'relname'}} ||= [];
        push @{ $ret->{ $data->{'relname'} } }, $data->{'attname'};
    }

    return $ret;
}

my %ur_data_type_for_vendor_data_type = (
     # DB type      UR Type
     'SMALLINT'  => ['Integer', undef],
     'BIGINT'    => ['Integer', undef],
     'SERIAL'    => ['Integer', undef],
     'TEXT'      => ['Text', undef],
     'BYTEA'     => ['Blob', undef],
     'CHARACTER VARYING' => ['Text', undef],
     'TIMESTAMP WITHOUT TIME ZONE' => ['DateTime', undef],
     'NUMERIC'   => ['Number', undef],

     'DOUBLE PRECISION' => ['Number', undef],
);
sub ur_data_type_for_data_source_data_type {
    my($class,$type) = @_;

    $type = $class->normalize_vendor_type($type);
    my $urtype = $ur_data_type_for_vendor_data_type{$type};
    unless (defined $urtype) {
        $urtype = $class->SUPER::ur_data_type_for_data_source_data_type($type);
    }
    return $urtype;
}

sub _vendor_data_type_for_ur_data_type {
    return ( BOOLEAN     => 'BOOLEAN',
             XML         => 'XML',
             shift->SUPER::_vendor_data_type_for_ur_data_type(),
            );
}

sub _alter_sth_for_selecting_blob_columns {
    my($self, $sth, $column_objects) = @_;

    for (my $n = 0; $n < @$column_objects; $n++) {
        next unless defined ($column_objects->[$n]);  # No metaDB info for this one
        if (uc($column_objects->[$n]->data_type) eq 'BLOB') {
            require DBD::Pg;
            $sth->bind_param($n+1, undef, { pg_type => DBD::Pg::PG_BYTEA() });
        }
    }
}

my $DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
my $TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.US';
sub cast_for_data_conversion {
    my($class, $left_type, $right_type, $operator, $sql_clause) = @_;

    my @retval = ('%s','%s');

    # compatible types
    if ($left_type->isa($right_type)
        or
        $right_type->isa($left_type)
    ) {
        return @retval;
    }

    # So far, the only casting is to support using 'like' and one or both are strings
    if ($operator ne 'like'
        or
        ( ! $left_type->isa('UR::Value::Text') and ! $right_type->isa('UR::Value::Text') )
    ) {
        return @retval;
    }

    # Figure out which one is the non-string
    my($data_type, $i) = $left_type->isa('UR::Value::Text')
                        ? ( $right_type, 1)
                        : ( $left_type, 0);

    if ($data_type->isa('UR::Value::Timestamp')) {
        $retval[$i] = qq{to_char(%s, '$TIMESTAMP_FORMAT')};

    } elsif ($data_type->isa('UR::Value::DateTime')) {
        $retval[$i] = qq{to_char(%s, '$DATE_FORMAT')};

    } else {
        @retval = $class->SUPER::cast_for_data_conversion($left_type, $right_type, $operator);
    }

    return @retval;
}

sub _resolve_order_by_clause_for_column {
    my($self, $column_name, $query_plan, $property_meta) = @_;

    my $column_clause = $column_name;

    my $is_text_type = $property_meta->is_text;
    if ($is_text_type) {
        # Tell the DB to sort the same order as Perl's cmp
        $column_clause .= q( COLLATE "C");
    }

    my $is_desc = $query_plan->order_by_column_is_descending($column_name);
    if ($is_desc) {
        $column_clause .= q( DESC);
    }

    return $column_clause;
}

sub _assure_schema_exists_for_table {
    my($self, $table_name, $dbh) = @_;

    $dbh ||= $self->get_default_handle;

    my ($schema_name, undef) = $self->_extract_schema_and_table_name($table_name);
    if ($schema_name) {
        my $exists = $dbh->selectrow_array("SELECT schema_name FROM information_schema.schemata WHERE schema_name = ?;",
            undef, $schema_name);
        unless ($exists) {
            $dbh->do("CREATE SCHEMA $schema_name")
                or Carp::croak("Could not create schema $schema_name: " . $dbh->errstr);
        }
    }
}

1;

=pod

=head1 NAME

UR::DataSource::Pg - PostgreSQL specific subclass of UR::DataSource::RDBMS

=head1 DESCRIPTION

This module provides the PostgreSQL-specific methods necessary for interacting with
PostgreSQL databases

=head1 SEE ALSO

L<UR::DataSource>, L<UR::DataSource::RDBMS>

=cut

