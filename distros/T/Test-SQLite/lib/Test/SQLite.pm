package Test::SQLite;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: SQLite setup/teardown for tests

our $VERSION = '0.0209';

use Moo;
use strictures 2;

use DBI;
use File::Copy;
use File::Temp ();


has database => (
    is        => 'ro',
    isa       => sub { die 'database does not exist' unless -e $_[0] },
    predicate => 'has_database',
);


has schema => (
    is        => 'ro',
    isa       => sub { die 'schema does not exist' unless -e $_[0] },
    predicate => 'has_schema',
);


has db_attrs => (
    is      => 'ro',
    default => sub { return { RaiseError => 1, AutoCommit => 1 } },
);


has dsn => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_dsn {
    my ($self) = @_;
    return 'dbi:SQLite:dbname=' . $self->_database->filename;
}


has dbh => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_dbh {
    my ($self) = @_;
    return DBI->connect( $self->dsn, '', '', $self->db_attrs );
}

has _database => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build__database {
    my ($self) = @_;

    my $filename = File::Temp->new( unlink => 1, suffix => '.db', EXLOCK => 0 );

    if ( $self->has_database ) {
        copy( $self->database, $filename )
            or die "Can't copy " . $self->database . ": $!";
    }
    elsif ( $self->has_schema ) {
        open my $schema, '<', $self->schema
            or die "Can't read " . $self->schema . ": $!";

        my $dbh = DBI->connect( "dbi:SQLite:dbname=$filename", '', '', { RaiseError => 1, AutoCommit => 0 } )
            or die "Can't connect to $filename: " . $DBI::errstr;

        my $sql = '';
        while ( my $line = readline($schema) ) {
            next if $line =~ /^\s*--/;
            next if $line =~ /^\s*$/;

            $sql .= $line;

            if ( $line =~ /;\s*$/ ) {
                $dbh->do($sql)
                    or die 'Error executing SQL for ' . $self->schema . ': ' . $dbh->errstr;

                $sql = '';
            }
        }

        $dbh->commit;

        $dbh->disconnect;
    }

    return $filename;
}


sub BUILD {
    my ( $self, $args ) = @_;
    die 'Schema and database may not be used at the same time.'
        if $self->has_database and $self->has_schema;
    die 'No schema or database given.'
        unless $self->has_database or $self->has_schema;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SQLite - SQLite setup/teardown for tests

=head1 VERSION

version 0.0209

=head1 SYNOPSIS

  use DBI;
  use Test::SQLite;

  my $sqlite = Test::SQLite->new(database => '/some/where/production.db');
  my $dbh = $sqlite->dbh;
  # Fiddle with the test database...
  $dbh->disconnect;

  $sqlite = Test::SQLite->new(
    schema   => '/some/where/schema.sql',
    db_attrs => { RaiseError => 1, AutoCommit => 0 },
  );
  # Explicitly use the dsn and db_attrs to connect:
  $dbh = DBI->connect($sqlite->dsn, '', '', $sqlite->db_attrs);
  # Fiddle with the test database...
  $dbh->commit;
  $dbh->disconnect;

=head1 DESCRIPTION

C<Test::SQLite> is loosely inspired by L<Test::PostgreSQL> and
L<Test::mysqld>, and creates a temporary db to use in tests.  Unlike
those modules, it is limited to setup/teardown of the test db given a
B<database> or B<schema> SQL file.  Also this module will return the
database B<dbh> handle and B<dsn> connection string.

=head1 ATTRIBUTES

=head2 database

The database to copy.

=head2 has_database

Boolean indicating that a database file was provided to the constructor.

=head2 schema

The SQL schema with which to create a test database.

* The SQL parsing done by this module does not handle triggers.

=head2 has_schema

Boolean indicating that a schema file was provided to the constructor.

=head2 db_attrs

DBI connection attributes.  Default: { RaiseError => 1, AutoCommit => 1 }

=head2 dsn

The database connection string.

=head2 dbh

A connected database handle based on the B<dsn> and B<db_attrs>.

=head1 METHODS

=head2 new

  $sqlite = Test::SQLite->new(%arguments);

Create a new C<Test::SQLite> object, which creates a temporary
database given a B<database> or B<schema>.

=head2 BUILD

Ensure that we are given either a B<database> or a B<schema> and not
both.

=head1 SEE ALSO

The F<t/01-methods.t> file in this distribution.

L<DBI>

L<File::Copy>

L<File::Temp>

L<Moo>

=head1 THANK YOU

Kaitlyn Parkhurst <symkat@symkat.com>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
