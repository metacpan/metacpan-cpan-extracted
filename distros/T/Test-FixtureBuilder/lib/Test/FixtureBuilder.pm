package Test::FixtureBuilder;
use strict;
use warnings;

our $VERSION = '0.001';

use Exporter::Declare;

use Scalar::Util qw/blessed/;
use Carp qw/croak confess/;

sub after_import {
    my $class = shift;
    my ($importer, $specs) = @_;
    $importer->FIXTURE_BUILDER_META->{class} = $class;
}

gen_default_export FIXTURE_BUILDER_META => sub {
    my $meta = { class => undef };
    return sub { $meta };
};

default_export fixture_db => sub {
    my $caller = caller;
    my ($name, $code) = @_;

    croak "'$caller' does not have metadata!"
        unless $caller->can('FIXTURE_BUILDER_META');

    my $meta = $caller->FIXTURE_BUILDER_META;

    croak "Cannot set db to '$name', already set to '$meta->{db}'"
        if exists $meta->{db};
    $meta->{db} = $name;

    $meta->{builder} = $meta->{class}->new(%$meta);

    my $success = eval { $code->($meta->{builder}); 1 };
    my $error = $@;

    delete $meta->{$_} for qw/db dbh builder/;

    die $error || "Unknown Error"
        unless $success;

    return $name;
};

default_export fixture_table => sub {
    my $caller = caller;
    my ($name, $code) = @_;

    croak "'$caller' does not have metadata!"
        unless $caller->can('FIXTURE_BUILDER_META');

    my $meta = $caller->FIXTURE_BUILDER_META;

    croak "Cannot set table to '$name', already set to '$meta->{table}'"
        if exists $meta->{table};
    $meta->{table} = $name;

    my $success = eval { $code->($meta->{builder}, $name); 1 };
    my $error = $@;

    delete $meta->{$_} for qw/table/;

    die $error || "Unknown Error"
        unless $success;

    return $name;
};

default_export fixture_row => sub {
    my $caller = caller;

    croak "'$caller' does not have metadata!"
        unless $caller->can('FIXTURE_BUILDER_META');

    my $meta = $caller->FIXTURE_BUILDER_META;

    my $row = @_ > 1 ? {@_} : $_[0];

    return $meta->{builder}->insert_row( $meta->{table} => $row );
};

sub name_to_handle {
    my $class = shift;
    my ($name) = @_;

    return $name if blessed $name;

    croak "I don't know how to convert '$name' to a database handle, override name_to_handle()";
}

sub new {
    my $class = shift;
    my %params = @_;

    my $self = bless {}, $class;

    for my $field ( keys %params ) {
        croak "'$field' is not a valid accessor for '$class'"
            unless $self->can($field);

        $self->$field($params{$field});
    }

    return $self;
}

sub db {
    my $self = shift;

    return $self->dbh
        unless @_;

    my ($name) = @_;

    my $dbh = $self->name_to_handle($name);
    croak "Could not get db handle for '$name'"
        unless $dbh;

    $self->dbh( $dbh );
}

for my $field (qw/dbh class/) {
    my $accessor = sub {
        my $self = shift;

        croak "Accessor '$field' called without instance!"
            unless blessed $self && $self->isa( __PACKAGE__ );

        ($self->{$field}) = @_ if @_;

        return $self->{$field};
    };
    no strict 'refs';
    *$field = $accessor;
}

sub insert_row {
    my $self = shift;
    my ($table, $row) = @_;

    my $dbh = $self->dbh || croak "No database handle set!";

    my $quoted_table = $dbh->quote_identifier(undef, undef, $table);
    my @vals = values %$row;
    my $cols = join ',' => map { $dbh->quote_identifier($_) } keys %$row;
    my $vals = join ',' => map { '?' } @vals;

    my $sth = $dbh->prepare("INSERT INTO $quoted_table ($cols) VALUES($vals)");
    $sth->execute(@vals);

    return eval { $dbh->last_insert_id } || 0;
}

sub insert_rows {
    my $self = shift;
    my ($table, @rows) = @_;

    $self->insert_row($table => $_) for @rows;
}

1;

__END__

=pod

=head1 NAME

Test::FixtureBuilder - Quickly define fixture data for unit tests

=head1 DESCRIPTION

When writing unit tests for applications it is often necessary to load some
basic data into a database. This data is often referred to fixture data. There
are several approaches to loading fixture data: Manual, From YAML files, or
code to create objects.

Sometimes you just want to shove some rows into a database, and you do not want
to be bothered with the SQL or the object->new calls. In those cases this
module is for you.

=head1 SYNOPSYS

There are two interfaces to this module.

=head2 DECLARE

The declarative interface is really quite nice.

B<NOTE:> You B<MUST> subclass Test::FixtureBuilder, or use a predefined
subclass in order to use the declarative form.

    package Test::FixtureBuilder::MyBuilder;

    use DBI;
    use DBD::SQLite;

    use base Test::FixtureBuilder;

    sub name_to_handle {
        my $class = shift;
        my ($name) = @_;
        return DBI->connect("dbi:SQLite:dbname=$name","","");
    }

    1;

Then to use it:

    use Test::FixtureBuilder::MyBuilder;

    fixture_db my_db => sub {
        fixture_table my_table => sub {
            fixture_row { col1 => 'val1', col2 => 'val2' };

            fixture_row { key => $_, col2 => 'xxx' }
                for 1 .. 10;
        };

        fixture_table my_table2 => sub {
            fixture_row { col1 => 'val1', col2 => 'val2' };
        };
    };

    fixture_db my_db2 => sub { ... };

    ...

    1;

=head2 OOP

    use Test::FixtureBuilder ();

    my $fb = Test::FixtureBuilder->new( dbh => $dbh );
    $fb->insert_row(tableA => { col1 => 'val1' });
    $fb->insert_row(tableB => { col1 => 'val1' });

    $fb->insert_rows(
        'tableX',
        { ... },
        { ... },
        ...
    );

=head1 EXPORTS

=over 4

=item fixture_db db_name => sub { ... }

Create a scope in which fixtures use the db_name database

=item fixture_table table_name => sub { ... }

Create a scope in which fixtures use the table_name table

=item fixture_row { col => val, ... }

=item fixture_row ( col => val, ... )

=item fixture_row col => val, ...

Load a row, you can use a hashref, or key/value pairs.

=item my $meta = $class->FIXTURE_BUILDER_META

Get the meta-object. Documented for completeness, you should not use this
directly.

=back

=head1 METHODS

=over 4

=item my $dbh = $class->name_to_handle($dbname)

Get a database handle from a name. You must override this before it will do
anything useful. The default behavior is to die unless the $dbname variable is
blessed in which case it is returned unchanged.

=item my $fb = $class->new(...)

Create a new instance. Any valid accessor can be specified at construction
time. This includes accessors for your specific subclass.

=item $class = $fb->class

Used internally.

=item $fb->db($dbname)

=item $dbh = $fb->db

Set the database by name (only useful if you override C<name_to_handle()>).
When no argument is given it behaves like C<dbh()>.

=item $fb->dbh($dbh)

=item $dbh = $fb->dbh

Get and/or set the database handle.

=item $fb->insert_row(table => { ... })

Insert a row into the specified table of the current database.

=item $fb->insert_rows(table => { ... }, { ... }, ...)

Insert multiple rows into the specified table of the current database.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 OTHER CREDITS

=over 4

=item DreamHost

I originally developed a tool very similar to this one for use at DreamHost in
our test suite. DreamHost gave me permission to release an open-source
implementation of the tool.

L<http://www.dreamhost.com>

=back

=head1 COPYRIGHT

Copyright (C) 2014 Chad Granum

Test-FixtureBuilder is free software; Standard perl license (GPL and Artistic).

Test-FixtureBuilder is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the license for more details.

=cut
