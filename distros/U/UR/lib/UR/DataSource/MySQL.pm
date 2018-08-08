package UR::DataSource::MySQL;
use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::MySQL',
    is => ['UR::DataSource::RDBMS'],
    is_abstract => 1,
);

# RDBMS API

sub driver { "mysql" }

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

# MySQL can't do an 'escape' clause with the 'like' operator
sub _default_sql_like_escape_string { undef };
sub _format_sql_like_escape_string { return }

sub can_savepoint { 1;} 

sub does_support_limit_offset {
    my($self, $bx) = @_;

    my $tmpl = $bx->template;
    if ($tmpl->offset and !defined($tmpl->limit)) {
        return 0;  # Can't have offset without limit
    } else {
        return 1;
    }
}

sub resolve_limit_offset_clause {
    my($self, $query_plan) = @_;

    my $limit = $self->_resolve_limit_value_from_query_plan($query_plan);
    my $offset = $self->_resolve_offset_value_from_query_plan($query_plan);

    if (defined($limit) and $offset) {
        return sprintf('limit %d, %d', $offset, $limit);
    } elsif (defined $limit) {
        return sprintf('limit %d', $limit);
    } else {
        return '';
    }
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
    return 1 if $table_name =~ /^(pg_|sql_|URMETA)/;
}

#
# for concurrency's sake we need to use dummy tables in place of sequence generators here, too
#


sub _get_sequence_name_for_table_and_column {
    my $self = shift->_singleton_object;
    my ($table_name,$column_name) = @_;
    
    my $dbh = $self->get_default_handle();
    
    # See if the sequence generator "table" is already there
    my $seq_table = sprintf('URMETA_%s_%s_SEQ', $table_name, $column_name);
    #$DB::single = 1;
    unless ($self->{'_has_sequence_generator'}->{$seq_table} or
            grep {$_ eq $seq_table} $self->get_table_names() ) {
        unless ($dbh->do("CREATE TABLE IF NOT EXISTS $seq_table (next_value integer PRIMARY KEY AUTO_INCREMENT)")) {
            die "Failed to create sequence generator $seq_table: ".$dbh->errstr();
        }
    }
    $self->{'_has_sequence_generator'}->{$seq_table} = 1;

    return $seq_table;
}

sub _get_next_value_from_sequence {
    my($self,$sequence_name) = @_;

    my $dbh = $self->get_default_handle();

    # FIXME can we use a statement handle with a wildcard as the table name here?
    unless ($dbh->do("INSERT into $sequence_name values(null)")) {
        die "Failed to INSERT into $sequence_name during id autogeneration: " . $dbh->errstr;
    }

    my $new_id = $dbh->last_insert_id(undef,undef,$sequence_name,'next_value');
    unless (defined $new_id) {
        die "last_insert_id() returned undef during id autogeneration after insert into $sequence_name: " . $dbh->errstr;
    }

    unless($dbh->do("DELETE from $sequence_name where next_value = $new_id")) {
        die "DELETE from $sequence_name for next_value $new_id failed during id autogeneration";
    }

    return $new_id;
}


sub get_bitmap_index_details_from_data_dictionary {
    # Mysql dosen't have bitmap indexes.
    return [];
}


sub set_savepoint {
my($self,$sp_name) = @_;

    my $dbh = $self->get_default_handle;
    my $sp = $dbh->quote($sp_name);
    $dbh->do("savepoint $sp_name");
}


sub rollback_to_savepoint {
my($self,$sp_name) = @_;

    my $dbh = $self->get_default_handle;
    my $sp = $dbh->quote($sp_name);
    $dbh->do("rollback to savepoint $sp_name");
}


sub _resolve_order_by_clause_for_column {
    my($self, $column_name, $query_plan, $property_meta) = @_;

    my $is_optional = $property_meta->is_optional;

    my $column_clause = $column_name;  # default, usual case
    if ($is_optional) {
        if ($query_plan->order_by_column_is_descending($column_name)) {
            $column_clause = "CASE WHEN $column_name ISNULL THEN 0 ELSE 1 END, $column_name DESC";
        } else {
            $column_clause = "CASE WHEN $column_name ISNULL THEN 1 ELSE 0 END, $column_name";
        }
    } elsif ($query_plan->order_by_column_is_descending($column_name)) {
        $column_clause = $column_name . ' DESC';
    }
    return $column_clause;
}



# FIXME This works on Mysql 4.x (and later?).  Mysql5 has a database called
# IMFORMATION_SCHEMA that may be more useful for these kinds of queries
sub get_unique_index_details_from_data_dictionary {
    my($self, $owner_name, $table_name) = @_;

    my $dbh = $self->get_default_handle();
    return undef unless $dbh;

    #$table_name = $dbh->quote($table_name);

    my $sql = qq(SHOW INDEX FROM $table_name FROM $owner_name);

    my $sth = $dbh->prepare($sql);
    return undef unless $sth;

    $sth->execute();

    my $ret;
    while (my $data = $sth->fetchrow_hashref()) {
        next if ($data->{'Non_unique'});
        $ret->{$data->{'Key_name'}} ||= [];
        push @{ $ret->{ $data->{'Key_name'} } }, $data->{'Column_name'};
    }

    return $ret;
}

sub get_column_details_from_data_dictionary {
    my $self = shift;

    # Mysql seems wierd about the distinction between catalog/database and schema/owner
    # For 'ur update classes', it works if we just pass in undef for catalog
    # The passed-in args are: $self,$catalog,$schema,$table,$column
    my $catalog = shift;

    return $self->SUPER::get_column_details_from_data_dictionary(undef, @_);
}

sub get_foreign_key_details_from_data_dictionary {
    my $self = shift;

    # Mysql requires undef in some fields instead of an empty string
    my @new_params = map { length($_) ? $_ : undef } @_;

    return $self->SUPER::get_foreign_key_details_from_data_dictionary(@new_params);
}

my %ur_data_type_for_vendor_data_type = (
     # DB type      UR Type
    'TINYINT'    => ['Integer', undef],
    'SMALLINT'   => ['Integer', undef],
    'MEDIUMINT'  => ['Integer', undef],
    'BIGINT'     => ['Integer', undef],

    'BINARY'     => ['Text', undef],
    'VARBINARY'  => ['Text', undef],
    'TINYTEXT'   => ['Text', undef],
    'MEDIUMTEXT' => ['Text', undef],
    'LONGTEXT'   => ['Text', undef],

    'TINYBLOB'   => ['Blob', undef],
    'MEDIUMBLOB' => ['Blob', undef],
    'LONGBLOB'   => ['Blob', undef],
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



1;

=pod

=head1 NAME

UR::DataSource::MySQL - MySQL specific subclass of UR::DataSource::RDBMS

=head1 DESCRIPTION

This module provides the MySQL-specific methods necessary for interacting with
MySQL databases

=head1 SEE ALSO

L<UR::DataSource>, L<UR::DataSource::RDBMS>

=cut
