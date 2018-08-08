package UR::DataSource::CSV;
use strict;
use warnings;

# There are still a few issues with actually using this thing:
#
# when running
# ur define datasource rdbms --dsn DBD:CSV:f_dir=/tmp/trycsv
# the f_dir=... part doesn't get put in as a "server" attribute.
# You have to add in it by hand as sub server {}
#
# after ur update classes, there aren't any id properties defined
# for your new classes, because there's no conclusive way to pick
# the right one - no unique constraints
#
# _get_sequence_name_for_table_and_column() and _get_next_value_from_sequence()
# aren't implemented yet, so creating new entities and sync_databases
# won't work
#
# There's a bug in even the latest SQL::Statement on CPAN where the processing
# of JOIN clauses uses a case sensitive match against upper-case stuff, when it
# should be lower-case.  It also cannot handle more than one join in the same
# statement
#
# with that out of the way... on to the show!

require UR;
our $VERSION = "0.47"; # UR $VERSION;

use File::Basename;

UR::Object::Type->define(
    class_name => 'UR::DataSource::CSV',
    is => ['UR::DataSource::RDBMS'],
    is_abstract => 1,
);

# RDBMS API

sub driver { "CSV" }  

sub owner { 
    undef
}

sub login {
    undef
}

sub auth {
    undef
}


sub path { 
    my $server = shift->server;

    my @server_opts = split(';', $server);
    foreach my $opt ( @server_opts )  {
        my($key,$value) = split('=',$opt);
        if ($key eq 'f_dir') {
            return $value;
        }
    }

    return;
}
    

sub can_savepoint { 0;}  # Dosen't support savepoints

sub _dbi_connect_args {
    my $self = shift;

    my @connection = $self->SUPER::_dbi_connect_args(@_);
    delete $connection[3]->{'AutoCommit'};   # DBD::CSV doesn't support autocommit being off
    return @connection;
}


sub _get_sequence_name_for_table_and_column {
    Carp::croak("Not implemented yet");

    my $self = shift->_singleton_object;
    my ($table_name,$column_name) = @_;
    
    my $dbh = $self->get_default_handle();
    
    # See if the sequence generator "table" is already there
    my $seq_table = sprintf('URMETA_%s_%s_seq', $table_name, $column_name);
    unless ($self->{'_has_sequence_generator'}->{$seq_table} or
            grep {$_ eq $seq_table} $self->get_table_names() ) {
        unless ($dbh->do("CREATE TABLE IF NOT EXISTS $seq_table (next_value integer PRIMARY KEY AUTOINCREMENT)")) {
            die "Failed to create sequence generator $seq_table: ".$dbh->errstr();
        }
    }
    $self->{'_has_sequence_generator'}->{$seq_table} = 1;

    return $seq_table;
}

sub _get_next_value_from_sequence {
    Carp::croak('Not implemented yet');

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


# Given a table name, return the complete pathname to it
# As ur update classes calls this, $table has been uppercased
# already (because most data sources uppercase table names),
# so we need to figure out which file they're talking about
sub _find_pathname_for_table {
    my $self = shift;
    my $table = shift;

    my $path = $self->path;

    my @all_files = glob("$path/*");
    # note: this only finds the first one
    foreach my $pathname ( @all_files ) {
        if (File::Basename::basename($pathname) eq $table) {
            return $pathname;
        }
    }

    return;
}

# column_info doesn't work against a DBD::CSV handle
sub get_column_details_from_data_dictionary {
    my($self,$catalog,$schema,$table,$column) = @_;

    # Convert the SQL wildcards to glob wildcards
    $table =~ tr/%_/*?/;

    # Convert the SQL wildcards to regex wildcards
    $column =~ s/%/\\w*/;
    $column =~ s/_/\\w/;
    my $column_regex = qr($column);

    my(@matching_files) = $self->_find_pathname_for_table($table);
    my @found_columns;
    foreach my $file ( @matching_files ) {
        my $table_name = File::Basename::basename($file);
        my $fh = IO::File->new($file);
        unless ($fh) {
            $self->warning_message("Can't open file $file for reading: $!");
            next;
        }

        my $header = $fh->getline();
        $header =~ s/\r|\n//g;  # Remove newline/CR
        
        my @columns = split($self->get_default_handle->{'csv_sep_char'} ||',' , $header);
        my $column_order = 0;
        foreach my $column_name ( @columns ) {
            $column_order++;
            next unless $column_name =~ m/$column_regex/;

            push @found_columns, { TABLE_CAT => $catalog,
                                   TABLE_SCHEM => $schema,
                                   TABLE_NAME => $table_name,
                                   COLUMN_NAME => $column_name,
                                   DATA_TYPE => 'STRING',   # what else could we put here?
                                   TYPE_NAME => 'STRING',
                                   NULLABLE => 1,           # all columns are nullable in CSV files
                                   IS_NULLABLE => 'YES',
                                   REMARKS => '',
                                   COLUMN_DEF => '',
                                   SQL_DATA_TYPE => '',  # FIXME shouldn't this be something related to DATA_TYPE
                                   SQL_DATETIME_SUB => '',
                                   CHAH_OCTET_LENGTH => undef,  # FIXME this should be the same as column_size, right?
                                   ORDINAL_POSITION => $column_order,
                                }
        }
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $self->get_default_handle->set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    my @returned_names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE TYPE_NAME COLUMN_SIZE
                             BUFFER_LENGTH DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF
                             SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE );
    my $returned_sth = $sponge->prepare("column_info $table", {
        rows => [ map { [ @{$_}{@returned_names} ] } @found_columns ],
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $self->get_default_handle->set_err($sponge->err(), $sponge->errstr());

    return $returned_sth;
}


# DBD::CSV doesn't support foreign key tracking
# returns a statement handle with no data to read
sub get_foreign_key_details_from_data_dictionary {
my($self,$fk_catalog,$fk_schema,$fk_table,$pk_catalog,$pk_schema,$pk_table) = @_;

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $self->get_default_handle->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    my @returned_names = qw( FK_NAME UK_TABLE_NAME UK_COLUMN_NAME FK_TABLE_NAME FK_COLUMN_NAME );
    my $table = $pk_table || $fk_table;
    my $returned_sth = $sponge->prepare("foreign_key_info $table", {
        rows => [],
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $self->get_default_handle->DBI::set_err($sponge->err(), $sponge->errstr());

    return $returned_sth;
}


sub get_bitmap_index_details_from_data_dictionary {
    # DBD::CSV dosen't support bitmap indicies, so there aren't any
    return [];
}


sub get_unique_index_details_from_data_dictionary {
    # DBD::CSV doesn't support unique constraints
    return {};
}

sub get_table_details_from_data_dictionary {
    my($self,$catalog,$schema,$table,$type) = @_;
    
    # DBD::CSV's table_info seems to always give you back all the "tables" even
    # if you only asked for details on one of them
    my $sth = $self->SUPER::get_table_details_from_data_dictionary($catalog,$schema,$table,$type);

    # Yeah, it's kind of silly to have to read in all the data and repackage it
    # back into another sth
    my @returned_details;
    while (my $row = $sth->fetchrow_arrayref()) {
        next unless ($row->[2] eq $table);
        push @returned_details, $row;
    }
        
    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $self->get_default_handle->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    my @returned_names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME TABLE_TYPE REMARKS );
    my $returned_sth = $sponge->prepare("table_info $table", {
        rows => \@returned_details,
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $self->get_default_handle->DBI::set_err($sponge->err(), $sponge->errstr());

    $returned_sth;
}



# By default, make a text dump of the database at commit time.
# This should really be a datasource property
sub dump_on_commit {
    0;
}


1;


=pod

=head1 NAME

UR::DataSource::CSV - Parent class for data sources using DBD::CSV

=head1 DESCRIPTION

UR::DataSource::CSV is a subclass of L<UR::DataSource::RDBMS> and can be
used for interacting with CSV files.  Because of the limitations of the
underlying modules (such as SQL::Statement only supporting one join at a
time), this module is deprecated.

L<UR::DataSource::File> implements a non-SQL interface for data files, and
is the proper way to use a file as a data source for class data.

=cut
