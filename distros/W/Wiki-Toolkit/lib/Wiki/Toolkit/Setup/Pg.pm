package Wiki::Toolkit::Setup::Pg;

use strict;

use vars qw( @ISA $VERSION $SCHEMA_VERSION );

use Wiki::Toolkit::Setup::Database;

@ISA = qw( Wiki::Toolkit::Setup::Database );
$VERSION = '0.11';

use DBI;
use Carp;

$SCHEMA_VERSION = $VERSION*100;

my $create_sql = {
    10 => {
        schema_info => [ qq|
CREATE TABLE schema_info (
  version   integer      NOT NULL default 0
)
|, qq|
INSERT INTO schema_info VALUES (10)
| ],

        node => [ qq|
CREATE SEQUENCE node_seq
|, qq|
CREATE TABLE node (
  id        integer      NOT NULL DEFAULT NEXTVAL('node_seq'),
  name      varchar(200) NOT NULL DEFAULT '',
  version   integer      NOT NULL default 0,
  text      text         NOT NULL default '',
  modified  timestamp without time zone    default NULL,
  moderate  boolean      NOT NULL default '0',
  CONSTRAINT pk_id PRIMARY KEY (id)
)
|, qq|
CREATE UNIQUE INDEX node_name ON node (name)
| ],

        content => [ qq|
CREATE TABLE content (
  node_id   integer      NOT NULL,
  version   integer      NOT NULL default 0,
  text      text         NOT NULL default '',
  modified  timestamp without time zone    default NULL,
  comment   text         NOT NULL default '',
  moderated boolean      NOT NULL default '1',
  verified  timestamp without time zone    default NULL,
  verified_info text     NOT NULL default '',
  CONSTRAINT pk_node_id PRIMARY KEY (node_id,version),
  CONSTRAINT fk_node_id FOREIGN KEY (node_id) REFERENCES node (id)
)
| ],

        internal_links => [ qq|
CREATE TABLE internal_links (
  link_from varchar(200) NOT NULL default '',
  link_to   varchar(200) NOT NULL default ''
)
|, qq|
CREATE UNIQUE INDEX internal_links_pkey ON internal_links (link_from, link_to)
| ],

        metadata => [ qq|
CREATE TABLE metadata (
  node_id        integer      NOT NULL,
  version        integer      NOT NULL default 0,
  metadata_type  varchar(200) NOT NULL DEFAULT '',
  metadata_value text         NOT NULL DEFAULT '',
  CONSTRAINT fk_node_id FOREIGN KEY (node_id) REFERENCES node (id)
)
|, qq|
CREATE INDEX metadata_index ON metadata (node_id, version, metadata_type, metadata_value)
| ]
    },
    11 => {
        schema_info => [ qq|
CREATE TABLE schema_info (
  version   integer      NOT NULL default 0
)
|, qq|
INSERT INTO schema_info VALUES (11)
| ],

        node => [ qq|
CREATE SEQUENCE node_seq
|, qq|
CREATE TABLE node (
  id        integer      NOT NULL DEFAULT NEXTVAL('node_seq'),
  name      varchar(200) NOT NULL DEFAULT '',
  version   integer      NOT NULL default 0,
  text      text         NOT NULL,
  modified  timestamp without time zone    default NULL,
  moderate  boolean      NOT NULL default '0',
  CONSTRAINT pk_id PRIMARY KEY (id)
)
|, qq|
CREATE UNIQUE INDEX node_name ON node (name)
| ],

        content => [ qq|
CREATE TABLE content (
  node_id   integer      NOT NULL,
  version   integer      NOT NULL default 0,
  text      text         NOT NULL,
  modified  timestamp without time zone    default NULL,
  comment   text,
  moderated boolean      NOT NULL default '1',
  verified  timestamp without time zone    default NULL,
  verified_info text,
  CONSTRAINT pk_node_id PRIMARY KEY (node_id,version),
  CONSTRAINT fk_node_id FOREIGN KEY (node_id) REFERENCES node (id)
)
| ],

        internal_links => [ qq|
CREATE TABLE internal_links (
  link_from varchar(200) NOT NULL default '',
  link_to   varchar(200) NOT NULL default ''
)
|, qq|
CREATE UNIQUE INDEX internal_links_pkey ON internal_links (link_from, link_to)
| ],

        metadata => [ qq|
CREATE TABLE metadata (
  node_id        integer      NOT NULL,
  version        integer      NOT NULL default 0,
  metadata_type  varchar(200) NOT NULL DEFAULT '',
  metadata_value text         NOT NULL,
  CONSTRAINT fk_node_id FOREIGN KEY (node_id) REFERENCES node (id)
)
|, qq|
CREATE INDEX metadata_index ON metadata (node_id, version, metadata_type, metadata_value)
| ]
    },
};

my %upgrades = (
    '10_to_11' => [
        qq|
ALTER TABLE node ALTER COLUMN text DROP DEFAULT
 |, qq|
ALTER TABLE content ALTER COLUMN text DROP DEFAULT
|, qq|
ALTER TABLE content ALTER COLUMN comment DROP DEFAULT
|, qq|
ALTER TABLE content ALTER COLUMN comment DROP NOT NULL
|, qq|
ALTER TABLE content ALTER COLUMN verified_info DROP DEFAULT
|, qq|
ALTER TABLE content ALTER COLUMN verified_info DROP NOT NULL
|, qq|
ALTER TABLE metadata ALTER COLUMN metadata_value DROP DEFAULT
|, qq|
UPDATE schema_info SET version = 11
|,
    ],
);

=head1 NAME

Wiki::Toolkit::Setup::Pg - Set up tables for a Wiki::Toolkit store in a Postgres database.

=head1 SYNOPSIS

  use Wiki::Toolkit::Setup::Pg;
  Wiki::Toolkit::Setup::Pg::setup($dbname, $dbuser, $dbpass, $dbhost);

Omit $dbhost if the database is local.

=head1 DESCRIPTION

Set up a Postgres database for use as a Wiki::Toolkit store.

=head1 FUNCTIONS

=over 4

=item B<setup>

  use Wiki::Toolkit::Setup::Pg;
  Wiki::Toolkit::Setup::Pg::setup($dbname, $dbuser, $dbpass, $dbhost);

or

  Wiki::Toolkit::Setup::Pg::setup( $dbh );

You can either provide an active database handle C<$dbh> or connection
parameters.                                                                    

If you provide connection parameters the following arguments are
mandatory -- the database name, the username and the password. The
username must be able to create and drop tables in the database.

The $dbhost argument is optional -- omit it if the database is local.

B<NOTE:> If a table that the module wants to create already exists,
C<setup> will leave it alone. This means that you can safely run this
on an existing L<Wiki::Toolkit> database to bring the schema up to date
with the current L<Wiki::Toolkit> version. If you wish to completely start
again with a fresh database, run C<cleardb> first.

=cut

sub setup {
    my @args = @_;
    my $dbh = _get_dbh( @args );
    my $disconnect_required = _disconnect_required( @args );
    my $wanted_schema = _get_wanted_schema( @args ) || $SCHEMA_VERSION;

    die "No schema information for requested schema version $wanted_schema\n"
        unless $create_sql->{$wanted_schema};

    # Check whether tables exist
    my $sql = "SELECT tablename FROM pg_tables
               WHERE tablename in ("
            . join( ",", map { $dbh->quote($_) } keys %{$create_sql->{$wanted_schema}} ) . ")";
    my $sth = $dbh->prepare($sql) or croak $dbh->errstr;
    $sth->execute;
    my %tables;
    while ( my $table = $sth->fetchrow_array ) {
        exists $create_sql->{$wanted_schema}->{$table} and $tables{$table} = 1;
    }

    # Do we need to upgrade the schema of existing tables?
    # (Don't check if no tables currently exist)
    my $upgrade_schema;
    if(scalar keys %tables > 0) {
        $upgrade_schema = Wiki::Toolkit::Setup::Database::get_database_upgrade_required($dbh,$wanted_schema);
    } else {
        print "Skipping schema upgrade check - no tables found\n";
    }

    # Set up tables if not found
    foreach my $required ( reverse sort keys %{$create_sql->{$wanted_schema}} ) {
        if ( $tables{$required} ) {
            print "Table $required already exists... skipping...\n";
        } else {
            print "Creating table $required... done\n";
            foreach my $sql ( @{ $create_sql->{$wanted_schema}->{$required} } ) {
                $dbh->do($sql) or croak $dbh->errstr;
            }
        }
    }

    # Do the upgrade if required
    if($upgrade_schema) {
        print "Upgrading schema: $upgrade_schema\n";
        my @updates = @{$upgrades{$upgrade_schema}};
        foreach my $update (@updates) {
            if(ref($update) eq "CODE") {
                &$update($dbh);
            } elsif(ref($update) eq "ARRAY") {
                foreach my $nupdate (@$update) {
                    $dbh->do($nupdate);
                }
            } else {
                $dbh->do($update);
            }
        }
    }

    # Clean up if we made our own dbh.
    $dbh->disconnect if $disconnect_required;
}

=item B<cleardb>

  use Wiki::Toolkit::Setup::Pg;

  # Clear out all Wiki::Toolkit tables from the database.
  Wiki::Toolkit::Setup::Pg::cleardb($dbname, $dbuser, $dbpass, $dbhost);

or

  Wiki::Toolkit::Setup::Pg::cleardb( $dbh );

You can either provide an active database handle C<$dbh> or connection
parameters.                                                                    

If you provide connection parameters the following arguments are
mandatory -- the database name, the username and the password. The
username must be able to drop tables in the database.

The $dbhost argument is optional -- omit it if the database is local.

Clears out all L<Wiki::Toolkit> store tables from the database. B<NOTE>
that this will lose all your data; you probably only want to use this
for testing purposes or if you really screwed up somewhere. Note also
that it doesn't touch any L<Wiki::Toolkit> search backend tables; if you
have any of those in the same or a different database see
L<Wiki::Toolkit::Setup::DBIxFTS> or L<Wiki::Toolkit::Setup::SII>, depending on
which search backend you're using.

=cut

sub cleardb {
    my @args = @_;
    my $dbh = _get_dbh( @args );
    my $disconnect_required = _disconnect_required( @args );

    print "Dropping tables... ";
    my $sql = "SELECT tablename FROM pg_tables
               WHERE tablename in ("
            . join( ",", map { $dbh->quote($_) } keys %{$create_sql->{$SCHEMA_VERSION}} ) . ")";
    foreach my $tableref (@{$dbh->selectall_arrayref($sql)}) {
        $dbh->do("DROP TABLE $tableref->[0] CASCADE") or croak $dbh->errstr;
    }

    $sql = "SELECT relname FROM pg_statio_all_sequences
               WHERE relname = 'node_seq'";
    foreach my $seqref (@{$dbh->selectall_arrayref($sql)}) {
        $dbh->do("DROP SEQUENCE $seqref->[0]") or croak $dbh->errstr;
    }

    print "done\n";

    # Clean up if we made our own dbh.
    $dbh->disconnect if $disconnect_required;
}

sub _get_dbh {
    # Database handle passed in.
    if ( ref $_[0] and ref $_[0] eq 'DBI::db' ) {
        return $_[0];
    }

    # Args passed as hashref.
    if ( ref $_[0] and ref $_[0] eq 'HASH' ) {
        my %args = %{$_[0]};
        if ( $args{dbh} ) {
            return $args{dbh};
    } else {
            return _make_dbh( %args );
        }
    }

    # Args passed as list of connection details.
    return _make_dbh(
                      dbname => $_[0],
                      dbuser => $_[1],
                      dbpass => $_[2],
                      dbhost => $_[3],
                    );
}

sub _get_wanted_schema {
    # Database handle passed in.
    if ( ref $_[0] and ref $_[0] eq 'DBI::db' ) {
        return undef;
    }

    # Args passed as hashref.
    if ( ref $_[0] and ref $_[0] eq 'HASH' ) {
        my %args = %{$_[0]};
        return $args{wanted_schema};
    }
}

sub _disconnect_required {
    # Database handle passed in.
    if ( ref $_[0] and ref $_[0] eq 'DBI::db' ) {
        return 0;
    }

    # Args passed as hashref.
    if ( ref $_[0] and ref $_[0] eq 'HASH' ) {
        my %args = %{$_[0]};
        if ( $args{dbh} ) {
            return 0;
    } else {
            return 1;
        }
    }

    # Args passed as list of connection details.
    return 1;
}

sub _make_dbh {
    my %args = @_;
    my $dsn = "dbi:Pg:dbname=$args{dbname}";
    $dsn .= ";host=$args{dbhost}" if $args{dbhost};
    my $dbh = DBI->connect($dsn, $args{dbuser}, $args{dbpass},
               { PrintError => 1, RaiseError => 1,
                 AutoCommit => 1 } )
        or croak DBI::errstr;
    return $dbh;
}

=back

=head1 ALTERNATIVE CALLING SYNTAX

As requested by Podmaster.  Instead of passing arguments to the methods as

  ($dbname, $dbuser, $dbpass, $dbhost)

you can pass them as

  ( { dbname => $dbname,
      dbuser => $dbuser,
      dbpass => $dbpass,
      dbhost => $dbhost
    }
  )

or indeed as

  ( { dbh => $dbh } )

Note that's a hashref, not a hash.

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002-2004 Kake Pugh.  All Rights Reserved.
     Copyright (C) 2006-2008 the Wiki::Toolkit team. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Wiki::Toolkit>, L<Wiki::Toolkit::Setup::DBIxFTS>, L<Wiki::Toolkit::Setup::SII>

=cut

1;
