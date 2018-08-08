package UR::DataSource::SQLite;
use strict;
use warnings;

use IO::Dir;
use File::Spec;
use File::Basename;
use version;

=pod

=head1 NAME

UR::DataSource::SQLite - base class for datasources using the SQLite3 RDBMS

=head1 SYNOPSIS

In the shell:

    ur define datasource sqlite

Or write the singleton to represent the source directly: 

    class Acme::DataSource::MyDB1 {
        is => 'UR::DataSource::SQLite',
        has_constant => [
            server => '/var/lib/acme-app/mydb1.sqlitedb'
        ]
    };

You may also use a directory containing *.sqlite3 files.  The primary database
must be named main.sqlite3.  All the other *.sqlite3 files are attached when
the database is opened.

    class Acme::DataSource::MyDB2 {
        is => 'UR::DataSource::SQLite',
        has_constant => [
            server => '/path/to/directory/'
        ]
    };

=cut

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::SQLite',
    is => ['UR::DataSource::RDBMS'],
    is_abstract => 1,
);

# RDBMS API

sub driver { "SQLite" }

sub default_owner {
    return 'main';
}

sub owner { default_owner() }

sub login {
    undef
}

sub auth {
    undef
}

sub create_default_handle {
    my $self = shift->_singleton_object();

    $self->_init_database;
    if ($self->_db_path_specifies_a_directory($self->server)) {
        return $self->_create_default_handle_from_directory();
    } else {
        return $self->SUPER::create_default_handle(@_);
    }
}

sub _create_default_handle_from_directory {
    my $self = shift;

    my $server_directory = $self->server;
    my $ext = $self->_extension_for_db;
    my $main_schema_file = File::Spec->catfile($server_directory, "main${ext}");
    -f $main_schema_file
        || UR::Util::touch_file($main_schema_file)
        || die "Could not create main schema file $main_schema_file: $!";

    my $server_sub_name = join('::', ref($self), 'server');

    my $dbh = do {
        no strict 'refs';
        no warnings 'redefine';
        local *$server_sub_name = sub { $main_schema_file };

        $self->SUPER::create_default_handle();
    };

    $self->_attach_all_schema_files_in_directory($dbh, $server_directory);
    return $dbh;
}

sub _attach_all_schema_files_in_directory {
    my($self, $dbh, $server_directory) = @_;
    my @schema_files = $self->_schema_files_in_directory($server_directory);

    local $dbh->{AutoCommit} = 1;

    my $main_db_file = join('', 'main', $self->_extension_for_db);
    foreach my $file ( @schema_files ) {
        next if $file eq $main_db_file;
        my $schema = $self->_schema_from_schema_filename($file);

        my $pathname = File::Spec->catfile($server_directory, $file);
        $dbh->do("ATTACH DATABASE '$pathname' as $schema")
            || Carp::croak("Could not attach schema file $file: ".$dbh->errstr);
    }
}

sub _schema_files_in_directory {
    my($self, $dir) = @_;

    my $dh = IO::Dir->new($dir);

    my @files;
    while (my $name = $dh->read) {
        my $pathname = File::Spec->catfile($dir, $name);
        next unless -f $pathname;
        push(@files, $name) if $self->_schema_from_schema_filename($name);
    }
    return @files;
}

sub _schema_from_schema_filename {
    my($self, $pathname) = @_;

    my($schema, $dir, $ext) = File::Basename::fileparse($pathname, $self->_extension_for_db);
    return $ext ? $schema : undef;
}

sub database_exists {
    my $self = shift;
    return 1 if -e $self->server;
    return 1 if -e $self->_data_dump_path; # exists virtually, and will dynamicaly instantiate
    return;
}

sub create_database {
    my $self = shift;
    die "Database exists!" if $self->database_exists;
    my $path = $self->server;
    return 1 if IO::File->new(">$path");
}

sub can_savepoint { 0;}  # Dosen't support savepoints

# SQLite API

sub _schema_path {
    return shift->_database_file_path() . '-schema';
}

sub _data_dump_path {
    return shift->_database_file_path() . '-dump';
}

# FIXME is there a way to make this an object parameter instead of a method
sub server {
    my $self = shift->_singleton_object();
    my $path = $self->__meta__->module_path;
    my $ext = $self->_extension_for_db;
    $path =~ s/\.pm$/$ext/ or Carp::croak("Odd module path $path.  Expected something endining in '.pm'");

    my $dir = File::Basename::dirname($path);
    return $path; 
}
*_database_file_path = \&server;


sub _extension_for_db {
    '.sqlite3';
}

sub _journal_file_path {
    my $self = shift->_singleton_object();
    return $self->server . "-journal";
}

sub _init_database {
    my $self = shift->_singleton_object();

    my $db_file     = $self->server;
    my $dump_file   = $self->_data_dump_path;
    my $schema_file = $self->_schema_path;

    my $db_time     = (stat($db_file))[9];
    my $dump_time   = (stat($dump_file))[9];
    my $schema_time = (stat($schema_file))[9];

    if ($schema_time && ((-e $db_file and $schema_time > $db_time) or (-e $dump_file and $schema_time > $dump_time))) {
        $self->warning_message("Schema file is newer than the db file or the dump file.  Replacing db_file $db_file.");
        my $dbbak_file = $db_file . '-bak';
        my $dumpbak_file = $dump_file . '-bak';
        unlink $dbbak_file if -e $dbbak_file;
        unlink $dumpbak_file if -e $dumpbak_file;
        rename $db_file, $dbbak_file if -e $db_file;
        rename $dump_file, $dumpbak_file if -e $dump_file;
        if (-e $db_file) {
            Carp::croak "Failed to move out-of-date file $db_file out of the way for reconstruction! $!";
        }
        if (-e $dump_file) {
            Carp::croak "Failed to move out-of-date file $dump_file out of the way for reconstruction! $!";
        }
    }
    if (-e $db_file) {
        if ($dump_time && ($db_time < $dump_time)) {
            my $bak_file = $db_file . '-bak';
            $self->warning_message("Dump file is newer than the db file.  Replacing db_file $db_file.");
            unlink $bak_file if -e $bak_file;
            rename $db_file, $bak_file;
            if (-e $db_file) {
                Carp::croak "Failed to move out-of-date file $db_file out of the way for reconstruction! $!";
            }
        }
    }

    # NOTE: don't make this an "else", since we might go into both branches because we delete the file above.
    unless (-e $db_file) {
        # initialize a new database from the one in the base class
        # should this be moved to connect time?

        # TODO: auto re-create things as needed based on timestamp

        if (-e $dump_file) {
            # create from dump
            $self->warning_message("Re-creating $db_file from $dump_file.");
            $self->_load_db_from_dump_internal($dump_file);
            unless (-e $db_file) {
                Carp::croak("Failed to import $dump_file into $db_file!");
            }
        }
        elsif ( (not -e $db_file) and (-e $schema_file) ) {
            # create from schema
            $self->warning_message("Re-creating $db_file from $schema_file.");
            $self->_load_db_from_dump_internal($schema_file);
            unless (-e $db_file) {
                Carp::croak("Failed to import $dump_file into $db_file!");
            }
        }
        elsif ($self->class ne __PACKAGE__) {
            # copy from the parent class (disabled)
            Carp::croak("No schema or dump file found for $db_file.\n  Tried schema path $schema_file\n  and dump path $dump_file\nIf you still have *sqlite3n* SQLite database files please rename them to *sqlite3*, without the 'n'");

            my $template_database_file = $self->SUPER::server();
            unless (-e $template_database_file) {
                Carp::croak("Missing template database file: $db_file!  Cannot initialize database for " . $self->class);
            }
            unless(File::Copy::copy($template_database_file,$db_file)) {
                Carp::croak("Error copying $db_file to $template_database_file to initialize database!");
            }
            unless(-e $db_file) {
                Carp::croak("File $db_file not found after copy from $template_database_file. Cannot initialize database!");
            }
        }
        else {
            Carp::croak("No db file found, and no dump or schema file found from which to re-construct a db file!");
        }
    }
    return 1;
}

*_init_created_dbh = \&init_created_handle;
sub init_created_handle
{
    my ($self, $dbh) = @_;
    return unless defined $dbh;
    $dbh->{LongTruncOk} = 0;
    # wait one minute busy timeout
    $dbh->func(1800000,'busy_timeout');
    return $dbh;
}

sub _ignore_table {
    my $self = shift;
    my $table_name = shift;
    return 1 if $table_name =~ /^(sqlite|\$|URMETA)/;
}


sub _get_sequence_name_for_table_and_column {
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


# Overriding this so we can force the schema to 'main' for older versions of SQLite
#
# NOTE: table_info (called by SUPER::get_table_details_from_data_dictionary) in older
# versions of DBD::SQLite does not return data for tables in other attached databases.
#
# This probably isn't an issue... Due to the limited number of people using older DBD::SQLite
# (of particular note is that OSX 10.5 and earlier use such an old version), interseted with
# the limited number of people using attached databases, it's probably not a problem.
# The commit_between_schemas test does do this.  If it turns out it is a problem, we could
# appropriate the code from recent DBD::SQLite::table_info
sub get_table_details_from_data_dictionary {
    my $self = shift;

    my $sth = $self->SUPER::get_table_details_from_data_dictionary(@_);
    my $sqlite_version = version->parse($DBD::SQLite::VERSION);
    my $needed_version = version->parse("1.26_04");
    if ($sqlite_version >= $needed_version || !$sth) {
        return $sth;
    }

    my($catalog,$schema,$table_name) = @_;

    my @tables;
    my @returned_names;
    while (my $info = $sth->fetchrow_hashref()) {
        #@returned_names ||= (keys %$info);
        unless (@returned_names) {
            @returned_names = keys(%$info);
        }
        $info->{'TABLE_SCHEM'} ||= 'main';
        push @tables, $info;
    }

    my $dbh = $self->get_default_handle();
    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    unless (@returned_names) {
        @returned_names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME TABLE_TYPE REMARKS );
    }
    my $returned_sth = $sponge->prepare("table_info $table_name", {
        rows => [ map { [ @{$_}{@returned_names} ] } @tables ],
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());

    return $returned_sth;
}


# DBD::SQLite doesn't implement column_info.  This is the UR::DataSource version of the same thing
sub get_column_details_from_data_dictionary {
    my($self,$catalog,$schema,$table,$column) = @_;

    my $dbh = $self->get_default_handle();

    # Convert the SQL wildcards to regex wildcards
    $column = '' unless defined $column;
    $column =~ s/%/.*/;
    $column =~ s/_/./;
    my $column_regex = qr(^$column$);

    my $sth_tables = $dbh->table_info($catalog, $schema, $table, 'TABLE');
    my @table_names = map { $_->{'TABLE_NAME'} } @{ $sth_tables->fetchall_arrayref({}) };

    my $override_owner;
    if ($DBD::SQLite::VERSION < 1.26_04) {
        $override_owner = 'main';
    }

    my @columns;
    foreach my $table_name ( @table_names ) {

        my $sth = $dbh->prepare("PRAGMA table_info($table_name)")
                          or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
        $sth->execute() or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

        while (my $info = $sth->fetchrow_hashref()) {

            next unless $info->{'name'} =~ m/$column_regex/;

            # SQLite doesn't parse our that type varchar(255) actually means type varchar size 255
            my $data_type = $info->{'type'};
            my $column_size;
            if ($data_type =~ m/(\S+)\s*\((\S+)\)/) {
                $data_type = $1;
                $column_size = $2;
            }

            my $node = {};
            $node->{'TABLE_CAT'} = $catalog;
            $node->{'TABLE_SCHEM'} = $schema || $override_owner;
            $node->{'TABLE_NAME'} = $table_name;
            $node->{'COLUMN_NAME'} = $info->{'name'};
            $node->{'DATA_TYPE'} = $data_type;
            $node->{'TYPE_NAME'} = $data_type;
            $node->{'COLUMN_SIZE'} = $column_size;
            $node->{'NULLABLE'} = ! $info->{'notnull'};
            $node->{'IS_NULLABLE'} = ($node->{'NULLABLE'} ? 'YES' : 'NO');
            $node->{'REMARKS'} = "";
            $node->{'SQL_DATA_TYPE'} = "";  # FIXME shouldn't this be something related to DATA_TYPE
            $node->{'SQL_DATETIME_SUB'} = "";
            $node->{'CHAR_OCTET_LENGTH'} = undef;  # FIXME this should be the same as column_size, right?
            $node->{'ORDINAL_POSITION'} = $info->{'cid'};
            $node->{'COLUMN_DEF'} = $info->{'dflt_value'};
            # Remove starting and ending 's that appear erroneously with string default values
            $node->{'COLUMN_DEF'} =~ s/^'|'$//g if defined ( $node->{'COLUMN_DEF'});

            push @columns, $node;
        }
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    my @returned_names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE TYPE_NAME COLUMN_SIZE
                             BUFFER_LENGTH DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF
                             SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE );
    my $returned_sth = $sponge->prepare("column_info $table", {
        rows => [ map { [ @{$_}{@returned_names} ] } @columns ],
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());

    return $returned_sth;
}


# SQLite doesn't store the name of a foreign key constraint in its metadata directly.
# We can guess at it from the SQL used in the table creation.  These regexes are probably
# sloppy. We could replace them if there were a good SQL parser.
sub _resolve_fk_name {
    my($self, $table_name, $column_list, $r_table_name, $r_column_list) = @_;

    if (@$column_list != @$r_column_list) {
        Carp::confess('There are '.scalar(@$column_list).' pk columns and '.scalar(@$r_column_list).' fk columns');
    }

    my($table_info) = $self->_get_info_from_sqlite_master($table_name, 'table');
    return unless $table_info;

    my $col_str = $table_info->{'sql'};
    $col_str =~ s/^\s+|\s+$//g;  # Remove leading and trailing whitespace
    $col_str =~ s/\s{2,}/ /g;    # Remove multiple spaces
    if ($col_str =~ m/^CREATE TABLE (\w+)\s*?\((.*?)\)$/is) {
        unless ($1 eq $table_name) {
            Carp::croak("Table creation SQL for $table_name is inconsistent.  Didn't find table name '$table_name' in string '$col_str'.  Found $1 instead.");
        }
        $col_str = $2;
    } else {
        Carp::croak("Couldn't parse SQL for $table_name");
    }


    my $fk_name;
    if (@$column_list > 1) {
        # Multiple column FKs must be specified as a table-wide constraint, and has a well-known format
        my $fk_list = '\s*' . join('\s*,\s*', @$column_list) . '\s*';
        my $uk_list = '\s*' . join('\s*,\s*', @$r_column_list) . '\s*';
        my $expected_to_find = sprintf('FOREIGN KEY\s*\(%s\) REFERENCES %s\s*\(%s\)',
                               $fk_list,
                               $r_table_name,
                               $uk_list);
        my $regex = qr($expected_to_find)i;

        if ($col_str =~ m/$regex/) {
            ($fk_name) = ($col_str =~ m/CONSTRAINT (\w+) FOREIGN KEY\s*\($fk_list\)/i);
        } else {
            # Didn't find anything...
            return;
        }

    } else {
        # single-column FK constraints can be specified a couple of ways...
        # First, try as a table-wide constraint
        my $col = $column_list->[0];
        my $r_col = $r_column_list->[0];
        if ($col_str =~ m/FOREIGN KEY\s*\($col\)\s*REFERENCES $r_table_name\s*\($r_col\)/i) {
            ($fk_name) = ($col_str =~ m/CONSTRAINT\s+(\w+)\s+FOREIGN KEY\s*\($col\)/i);
        } else {
            while ($col_str) {
                # Try parsing each of the column definitions
                # commas can't appear in here except to separate each column, right?
                my $this_col;
                if ($col_str =~ m/^(.*?)\s*,\s*(.*)/) {
                    $this_col = $1;
                    $col_str = $2;
                } else {
                    $this_col = $col_str;
                    $col_str = '';
                }
                
                my($col_name, $col_type) = ($this_col =~ m/^(\w+) (\w+)/);
                next unless ($col_name and
                             $col_name eq $col);

                if ($this_col =~ m/REFERENCES $r_table_name\s*\($r_col\)/i) {
                    # It's the right column, and there's a FK constraint on it
                    # Did the FK get a name?
                    ($fk_name) = ($this_col =~ m/CONSTRAINT (\w+) REFERENCES/i);
                    last;
                } else {   
                    # It's the right column, but there's no FK
                    return;
                }
            }
        }
    }

    # The constraint didn't have a name.  Make up something that'll likely be unique
    $fk_name ||= join('_', $table_name, @$column_list, $r_table_name, @$r_column_list, 'fk');
    return $fk_name;
}


# We'll only support specifying $fk_table or $pk_table but not both
# $fk_table refers to the table where the fk is attached
# $pk_table refers to the table the pk points to - where the primary key exists
sub get_foreign_key_details_from_data_dictionary {
my($self, $pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table) = @_;

    # first, build a data structure to collect columns of the same foreign key together
    my @returned_fk_info;
    if ($fk_table) {
        @returned_fk_info = $self->_get_foreign_key_details_for_fk_table_name($fk_schema, $fk_table);

    } elsif ($pk_table) {
        # We'll have to loop through each table in the DB and find FKs that reference
        # the named table

        my @tables = $self->_get_info_from_sqlite_master(undef,'table');
        TABLE:
        foreach my $table_data ( @tables ) {
            my $from_table = $table_data->{'table_name'};
            push @returned_fk_info, $self->_get_foreign_key_details_for_fk_table_name($fk_schema, $from_table, sub { $_[0]->{table} eq $pk_table });
        }
    } else {
        Carp::croak("Can't get_foreign_key_details_from_data_dictionary(): either pk_table ($pk_table) or fk_table ($fk_table) are required");
    }

    my $dbh = $self->get_default_handle;
    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");

    my @returned_names = qw( UK_TABLE_CAT UK_TABLE_SCHEM UK_TABLE_NAME UK_COLUMN_NAME
                             FK_TABLE_CAT FK_TABLE_SCHEM FK_TABLE_NAME FK_COLUMN_NAME
                             ORDINAL_POSITION UPDATE_RULE DELETE_RULE FK_NAME UK_NAME DEFERABILITY );
    my $table = $pk_table || $fk_table;
    my $returned_sth = $sponge->prepare("foreign_key_info $table", {
        rows => [ map { [ @{$_}{@returned_names} ] } @returned_fk_info ],
        NUM_OF_FIELDS => scalar @returned_names,
        NAME => \@returned_names,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());

    return $returned_sth;
}

# used by _get_foreign_key_details_for_fk_table_name to convert the on_delete or on_update
# string into the number code commonly returnd by DBI
my %update_delete_action_to_numeric_code = (
    CASCADE       => 0,
    RESTRICT      => 1,
    'SET NULL'    => 2,
    'NO ACTION'   => 3,
    'SET DEFAULT' => 4,
);

sub _get_foreign_key_details_for_fk_table_name {
    my($self, $fk_schema_name, $fk_table_name, $accept_rows) = @_;
    $accept_rows ||= sub { 1 };  # default is accept all

    $fk_schema_name ||= 'main';
    my $qualified_table_name = join('.', $fk_schema_name, $fk_table_name);

    my $dbh = $self->get_default_handle;
    my $fksth = $dbh->prepare("PRAGMA foreign_key_list($fk_table_name)")
                  or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    unless ($fksth->execute()) {
        $self->error_message("foreign_key_list execute failed: $DBI::errstr");
        return;
    }

    my @fk_rows_this_table;
    my(@column_list, @r_column_list);
    while (my $row = $fksth->fetchrow_hashref) {
        next unless ($accept_rows->($row));

        my %fk_info_row = ( FK_TABLE_NAME => $fk_table_name,
                            FK_TABLE_SCHEM => $fk_schema_name,
                            UK_TABLE_SCHEM => $fk_schema_name, # SQLite doesn't tell us what attached DB it's from, so we'll guess
                            UPDATE_RULE => $update_delete_action_to_numeric_code{$row->{on_update}},
                            DELETE_RULE => $update_delete_action_to_numeric_code{$row->{on_delete}},
                            ORDINAL_POSITION => $row->{seq} + 1,
                          );
        @fk_info_row{'FK_COLUMN_NAME','UK_TABLE_NAME','UK_COLUMN_NAME'}
            = @$row{'from','table','to'};

        push @fk_rows_this_table, \%fk_info_row;

        push @column_list, $row->{from};
        push @r_column_list, $row->{to}
    }

    if (@fk_rows_this_table) {
        my $fk_name = $self->_resolve_fk_name($fk_rows_this_table[0]->{FK_TABLE_NAME},
                                          \@column_list,
                                          $fk_rows_this_table[0]->{UK_TABLE_NAME},  # They'll all have the same table, right?
                                          \@r_column_list);
        foreach my $fk_info_row ( @fk_rows_this_table ) {
            $fk_info_row->{FK_NAME} = $fk_name;
        }
        @fk_rows_this_table = sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} } @fk_rows_this_table;
    }
    return @fk_rows_this_table;
}

sub get_bitmap_index_details_from_data_dictionary {
    # SQLite dosen't support bitmap indicies, so there aren't any
    return [];
}


sub get_unique_index_details_from_data_dictionary {
    my($self, $owner_name, $table_name) = @_;

    my $dbh = $self->get_default_handle();
    return undef unless $dbh;

    my($index_list_fcn, $index_info_fcn) = ('index_list','index_info');
    if ($owner_name) {
        $index_list_fcn = "${owner_name}.${index_list_fcn}";
        $index_info_fcn = "${owner_name}.${index_info_fcn}";
    }

    my $idx_sth = $dbh->prepare(qq(PRAGMA ${index_list_fcn}($table_name)));

    return undef unless $idx_sth;

    $idx_sth->execute();

    my $ret = {};
    while(my $data = $idx_sth->fetchrow_hashref()) {
        next unless ($data->{'unique'});

        my $idx_name = $data->{'name'};
        my $idx_item_sth = $dbh->prepare(qq(PRAGMA ${index_info_fcn}($idx_name)));
        $idx_item_sth->execute();
        while(my $index_item = $idx_item_sth->fetchrow_hashref()) {
            $ret->{$idx_name} ||= [];
            push( @{$ret->{$idx_name}}, $index_item->{'name'});
        }
    }

    return $ret;
}


# By default, make a text dump of the database at commit time.
# This should really be a datasource property
sub dump_on_commit {
    0;
}

# We're overriding commit from UR::DS::commit() to add the behavior that after
# the actual commit happens, we also make a dump of the database in text format
# so that can be version controlled
sub commit {
    my $self = shift;

    my $has_no_pending_trans = (!-f $self->_journal_file_path());   

    my $worked = $self->SUPER::commit(@_);
    return unless $worked;

    my $db_filename = $self->server();
    my $dump_filename = $self->_data_dump_path();

    return 1 if ($has_no_pending_trans);
    
    return 1 unless $self->dump_on_commit or -e $dump_filename;
    
    return $self->_dump_db_to_file_internal();
}


# Get info out of the sqlite_master table.  Returns a hashref keyed by 'name'
# columns are:
#     type - 'table' or 'index'
#     name - Name of the object
#     table_name - name of the table this object references.  For tables, it's the same as name, 
#            for indexes, it's the name of the table it's indexing
#     rootpage - Used internally by sqlite
#     sql - The sql used to create the thing
sub _get_info_from_sqlite_master {
    my($self, $name,$type) = @_;

    my($schema, @where, @exec_values);
    if ($name) {
        ($schema, $name) = $self->_resolve_owner_and_table_from_table_name($name);
        push @where, 'name = ?';
        push @exec_values, $name;
    }
    if ($type) {
        push @where, 'type = ?';
        push @exec_values, $type;
    }

    my $sqlite_master_table = $schema
                                ? "${schema}.sqlite_master"
                                : 'sqlite_master';
    my $sql = "select * from $sqlite_master_table";
    if (@where) {
        $sql .= ' where '.join(' and ', @where);
    }

    my $dbh = $self->get_default_handle();
    my $sth = $dbh->prepare($sql);
    unless ($sth) {
        no warnings;
        $self->error_message("Can't get table details for name $name and type $type: ".$dbh->errstr);
        return;
    }

    unless ($sth->execute(@exec_values)) {
        no warnings;
        $self->error_message("Can't get table details for name $name and type $type: ".$dbh->errstr);
        return;
    }

    my @rows;
    while (my $row = $sth->fetchrow_arrayref()) {
        my $item;
        @$item{'type','name','table_name','rootpage','sql'} = @$row;
        # Force all names to lower case so we can find them later
        push @rows, $item;
    }

    return @rows;
}


# This is used if, for whatever reason, we can't sue the sqlite3 command-line
# program to load up the database.  We'll make a good-faith effort to parse
# the SQL text, but it won't be fancy.  This is intended to be used to initialize
# meta DB dumps, so we should have to worry about escaping quotes, multi-line
# statements, etc.
#
# The real DB file should be moved out of the way before this is called.  The existing
# DB file will be removed.
sub _load_db_from_dump_internal {
    my $self = shift;
    my $file_name = shift;

    my $fh = IO::File->new($file_name);
    unless ($fh) {
        Carp::croak("Can't open DB dump file $file_name: $!");
    }

    my $db_file = $self->server;
    if (-f $db_file) {
        unless(unlink($db_file)) {
            Carp::croak("Can't remove DB file $db_file: $!");
        }
    }

    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file",'','',{ AutoCommit => 0, RaiseError => 0 });
    unless($dbh) {
        Carp::croak("Can't create DB handle for file $db_file: $DBI::errstr");
    }

    my $dump_file_contents = do { local( $/ ) ; <$fh> };
    my @sql = split(';',$dump_file_contents);

    for (my $i = 0; $i < @sql; $i++) {
        my $sql = $sql[$i];
        next unless ($sql =~ m/\S/);  # Skip blank lines
        next if ($sql =~ m/BEGIN TRANSACTION|COMMIT/i);  # We're probably already in a transaction

        # Is it restoring the foreign_keys setting?
        if ($sql =~ m/PRAGMA foreign_keys\s*=\s*(\w+)/) {
            my $value = $1;
            my $fk_setting = $self->_get_foreign_key_setting($dbh);
            if (! defined($fk_setting)) {
                # This version of SQLite cannot enforce foreign keys.
                # Print a warning message if they're trying to turn it on.
                # also, remember the setting so we can preserve its value
                # in _dump_db_to_file_internal()
                $self->_cache_foreign_key_setting_from_file($value);
                if ($value ne 'OFF') {
                    $self->warning_message("Data source ".$self->id." does not support foreign key enforcement, but the dump file $db_file attempts to turn it on");
                }
                next;
            }
        }

        unless ($dbh->do($sql)) {
            Carp::croak("Error processing SQL statement $i from DB dump file:\n$sql\nDBI error was: $DBI::errstr\n");
        }
    }

    $dbh->commit();
    $dbh->disconnect();

    return 1;
}


sub _cache_foreign_key_setting_from_file {
    my $self = shift;

    our %foreign_key_setting_from_file;
    my $id = $self->id;

    if (@_) {
        $foreign_key_setting_from_file{$id} = shift;
    }
    return $foreign_key_setting_from_file{$id};
}

# Is foreign key enforcement on or off?
# returns undef if this version of SQLite cannot enforce foreign keys
sub _get_foreign_key_setting {
    my $self = shift;
    my $dbh = shift;
    my $id = $self->id;

    our %foreign_key_setting;
    unless (exists $foreign_key_setting{$id}) {
        $dbh ||= $self->get_default_handle;
        my @row = $dbh->selectrow_array('PRAGMA foreign_keys');
        $foreign_key_setting{$id} = $row[0];
    }
    return $foreign_key_setting{$id};
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

sub _resolve_limit_value_from_query_plan {
    my($self, $query_plan) = @_;
    my $limit = $query_plan->limit;
    return (!defined($limit) and $query_plan->offset)
            ? -1
            : $limit;
}


sub _dump_db_to_file_internal {
    my $self = shift;

    my $fk_setting = $self->_get_foreign_key_setting();

    my $file_name = $self->_data_dump_path();
    unless (-w $file_name) {
        # dump file isn't writable...
        return 1;
    }

    my $fh = IO::File->new($file_name, '>');
    unless ($fh) {
        Carp::croak("Can't open DB dump file $file_name for writing: $!");
    }

    my $db_file = $self->server;
    my $dbh = $self->get_default_handle;
    unless ($dbh) {
        Carp::croak("Can't create DB handle for file $db_file: $DBI::errstr");
    }

    if (defined $fk_setting) {
        # Save the value of the foreign_keys setting, if it's supported
        $fh->print('PRAGMA foreign_keys = ' . ( $fk_setting ? 'ON' : 'OFF' ) .";\n");
    } else {
        # If not supported, but if _load_db_from_dump_internal came across the value, preserve it
        $fk_setting = $self->_cache_foreign_key_setting_from_file;
        if (defined $fk_setting) {
            $fh->print("PRAGMA foreign_keys = $fk_setting;\n");
        }
    }

    $fh->print("BEGIN TRANSACTION;\n");

    my @tables = $self->_get_table_names_from_data_dictionary();
    foreach my $qualified_table ( @tables ) {
        my(undef, $table) = $self->_resolve_owner_and_table_from_table_name($qualified_table);
        my($item_info) = $self->_get_info_from_sqlite_master($table);
        my $creation_sql = $item_info->{'sql'};
        $creation_sql .= ";" unless(substr($creation_sql, -1, 1) eq ";");
        $creation_sql .= "\n" unless(substr($creation_sql, -1, 1) eq "\n");

        $fh->print($creation_sql);

        if ($item_info->{'type'} eq 'table') {
            my $sth = $dbh->prepare("select * from $table");
            unless ($sth) {
                Carp::croak("Can't retrieve data from table $table: $DBI::errstr");
            }
            unless($sth->execute()) {
                Carp::croak("execute() failed while retrieving data for table $table: $DBI::errstr");
            }

            while(my @row = $sth->fetchrow_array) {
                foreach my $col ( @row ) {
                    if (! defined $col) {
                        $col = 'null';
                    } elsif ($col =~ m/\D/ or length($col) == 0) {
                        $col = "'" . $col . "'";  # Put quotes around non-numeric stuff
                    }
                }
                $fh->printf("INSERT INTO %s VALUES(%s);\n",
                            $table,
                            join(',', @row));
            }
        }
    }
    $fh->print("COMMIT;\n");
    $fh->close();

    $dbh->disconnect();

    return 1;
}
            

sub _create_dbh_for_alternate_db {
    my($self, $connect_string) = @_;

    my $match_dbname = qr{dbname=([^;]+)}i;
    my($db_file) = $connect_string =~ m/$match_dbname/;
    $db_file
        || Carp::croak("Cannot determine dbname for alternate DB from dbi connect string $connect_string");

    if ($self->_db_path_specifies_a_directory($db_file)) {
        mkdir $db_file;
        my $main_schema_file = join('', 'main', $self->_extension_for_db);
        $db_file = File::Spec->catfile($db_file, $main_schema_file);

        $connect_string =~ s/$match_dbname/dbname=$db_file/;
    }

    my $dbh = $self->SUPER::_create_dbh_for_alternate_db($connect_string);
    return $dbh;
}

sub _db_path_specifies_a_directory {
    my($self, $pathname) = @_;
    return (-d $pathname) || ($pathname =~ m{/$});
}

sub _assure_schema_exists_for_table {
    my($self, $table_name, $dbh) = @_;
    $dbh ||= $self->get_default_handle;

    my($schema_name, undef) = $self->_extract_schema_and_table_name($table_name);
    if ($schema_name
        and
        ! $self->is_schema_attached($schema_name, $dbh)
    ) {
        # pretend we have schemas

        my($main_filename) = $dbh->{Name} =~ m/(?:dbname=)*(.*)/;
        my $directory = File::Basename::dirname($main_filename);
        my $schema_filename = File::Spec->catfile($directory, "${schema_name}.sqlite3");
        unless (UR::Util::touch_file($schema_filename)) {
            Carp::carp("touch_file $schema_filename failed: $!");
            return;
        }
        unless ($dbh->do(qq(ATTACH DATABASE '$schema_filename' as $schema_name))) {
            Carp::carp("Cannot attach file $schema_filename as $schema_name: ".$dbh->errstr);
            return;
        }
    }
}

sub attached_schemas {
    my($self, $dbh) = @_;
    $dbh ||= $self->get_default_handle;

    # Statement returns id, schema, filename
    my $sth = $dbh->prepare('PRAGMA database_list') || Carp::croak("Cannot list attached databases: ".$dbh->errstr);
    $sth->execute();
    my %schemas = map { $_->[1] => $_->[2] }
                         @{ $sth->fetchall_arrayref };
    return \%schemas;
}

sub is_schema_attached {
    my($self, $schema, $dbh) = @_;
    $dbh ||= $self->get_default_handle;

    my $schemas = $self->attached_schemas($dbh);
    return exists $schemas->{$schema};
}

1;
