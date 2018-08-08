package UR::DataSource::Meta;

# The datasource for metadata describing the tables, columns and foreign
# keys in the target datasource

use strict;
use warnings;

use version;
use DBD::SQLite;

use UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::Meta',
    is => ['UR::DataSource::SQLite'],
    has_constant => [
        owner => { value => 'main' },
    ],
);

sub _resolve_class_name_for_table_name_fixups {
    my $self = shift->_singleton_object;

    if ($_[0] =~ m/Dd/) {
        $_[0] = "DataSource::RDBMS::";
    }

    return @_;
}

# Do a DB dump at commit time
sub dump_on_commit { 1; }

# This is the template for the schema:
our $METADATA_DB_SQL =<<EOS;
CREATE TABLE IF NOT EXISTS dd_bitmap_index (
    data_source varchar NOT NULL,
    owner varchar,
    table_name varchar NOT NULL,
    bitmap_index_name varchar NOT NULL,
    PRIMARY KEY (data_source, table_name, bitmap_index_name)
);
CREATE TABLE IF NOT EXISTS dd_fk_constraint (
    data_source varchar NOT NULL,
    owner varchar,
    r_owner varchar,
    table_name varchar NOT NULL,
    r_table_name varchar NOT NULL,
    fk_constraint_name varchar NOT NULL,
    last_object_revision timestamp NOT NULL,
    PRIMARY KEY(data_source, table_name, r_table_name, fk_constraint_name)
);
CREATE TABLE IF NOT EXISTS dd_fk_constraint_column (
    fk_constraint_name varchar NOT NULL,
    data_source varchar NOT NULL,
    owner varchar NOT NULL,
    table_name varchar NOT NULL,
    r_table_name varchar NOT NULL,
    column_name varchar NOT NULL,
    r_column_name varchar NOT NULL,

    PRIMARY KEY(data_source, table_name, fk_constraint_name, column_name)
);
CREATE TABLE IF NOT EXISTS dd_pk_constraint_column (
    data_source varchar NOT NULL,
    owner varchar,
    table_name varchar NOT NULL,
    column_name varchar NOT NULL,
    rank integer NOT NULL,
    PRIMARY KEY (data_source,table_name,column_name,rank)
);
CREATE TABLE IF NOT EXISTS dd_table (
     data_source varchar NOT NULL,
     owner varchar,
     table_name varchar NOT NULL,
     table_type varchar NOT NULL,
     er_type varchar NOT NULL,
     last_ddl_time timestamp,
     last_object_revision timestamp NOT NULL,
     remarks varchar,
     PRIMARY KEY(data_source, table_name)
);
CREATE TABLE IF NOT EXISTS dd_table_column (
    data_source varchar NOT NULL,
    owner varchar,
    table_name varchar NOT NULL,
    column_name varchar NOT NULL,
    data_type varchar NOT NULL,
    data_length varchar,
    nullable varchar NOT NULL,
    last_object_revision timestamp NOT NULL,
    remarks varchar,
    PRIMARY KEY(data_source, table_name, column_name)
);
CREATE TABLE IF NOT EXISTS dd_unique_constraint_column (
    data_source varchar NOT NULL,
    owner varchar,
    table_name varchar NOT NULL,
    constraint_name varchar NOT NULL,
    column_name varchar NOT NULL,
    PRIMARY KEY (data_source,table_name,constraint_name,column_name)
);
EOS

our $module_template=<<EOS;
package %s;

use warnings;
use strict;

use UR;

%s

1;
EOS

# This is a bit ugly until the db cache is symmetrical with the other transactional stuff
# It is run by the "ur update schema" command 
sub generate_for_namespace {
    my $class = shift;
    my $namespace_name = shift;
    
    Carp::confess('Refusing to make MetaDB for the UR namespace') if $namespace_name eq 'UR';

    my $namespace_path = $namespace_name->__meta__->module_path();

    my $meta_datasource_name = $namespace_name . '::DataSource::Meta';
    my $meta_datasource = UR::Object::Type->define(
        class_name => $meta_datasource_name, 
        is => 'UR::DataSource::Meta',
        is_abstract => 0,
    );
    my $meta_datasource_src = $meta_datasource->resolve_module_header_source();
    my $meta_datasource_filename = $meta_datasource->module_base_name();

    my $meta_datasource_filepath = $namespace_path;
    return unless defined($meta_datasource_filepath);  # This namespace could be fabricated at runtime

    $meta_datasource_filepath =~ s/.pm//;
    $meta_datasource_filepath .= '/DataSource';
    mkdir($meta_datasource_filepath);
    unless (-d $meta_datasource_filepath) {
        die "Failed to create directory $meta_datasource_filepath: $!";
    } 
    $meta_datasource_filepath .= '/Meta.pm';
 
    # Write the Meta DB datasource Module
    if (-e $meta_datasource_filepath) {
        Carp::croak("Can't create new MetaDB datasource Module $meta_datasource_filepath: File already exists");
    }
    my $fh = IO::File->new("> $meta_datasource_filepath");
    unless ($fh) {
        Carp::croak("Can't create MetaDB datasource Module $meta_datasource_filepath: $!");
    }
    $fh->printf($module_template, $meta_datasource_name, $meta_datasource_src);

    # Write the skeleton SQLite file
    my $meta_db_file = $meta_datasource->class_name->_data_dump_path;
    IO::File->new(">$meta_db_file")->print($UR::DataSource::Meta::METADATA_DB_SQL);
    
    return ($meta_datasource, $meta_db_file);
}

sub _dbi_connect_args {
    my $self = shift;

    my @connection = $self->SUPER::_dbi_connect_args(@_);

    if(version->parse($DBD::SQLite::VERSION) >= version->parse('1.38_01')) {
        my $connect_attr = $connection[3] ||= {};
        $connect_attr->{sqlite_use_immediate_transaction} = 0;
    }

    return @connection;
}

1;

=pod

=head1 NAME

UR::DataSource::Meta - Data source for the MetaDB

=head1 SYNOPSIS

  my $meta_table = UR::DataSource::RDBMS::Table->get(
                       table_name => 'DD_TABLE'
                       namespace => 'UR',
                   );

  my @myapp_tables = UR::DataSource::RDBMS::Table->get(
                       namespace => 'MyApp',
                   );

=head1 DESCRIPTION

UR::DataSource::Meta a datasource that contains all table/column meta
data for the UR namespace itself.  Essentially the schema schema.

=head1 INHERITANCE

UR::DataSource::Meta is a subclass of L<UR::DataSource::SQLite>

=head1 get() required parameters

C<namespace> or C<data_source> are required parameters when calling C<get()>
on any MetaDB-sourced object types.

=cut
