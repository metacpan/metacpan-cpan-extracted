package Wiki::Toolkit::Setup::DBIxFTSMySQL;

use strict;

use vars qw( $VERSION );
$VERSION = 0.04;

use DBI;
use DBIx::FullTextSearch;
use Carp;

=head1 NAME

Wiki::Toolkit::Setup::DBIxFTSMySQL - set up fulltext indexes for Wiki::Toolkit

=head1 SYNOPSIS

  use Wiki::Toolkit::Setup::DBIxFTSMySQL;
  Wiki::Toolkit::Setup::DBIxFTSMySQL::setup($dbname, $dbuser, $dbpass, $dbhost);

Omit $dbhost if the database is local.

=head1 DESCRIPTION

Set up DBIx::FullTextSearch indexes for use with Wiki::Toolkit. Has only
one function, C<setup>, which takes as arguments B<either> the
database name, the username and the password B<or> a database handle
. The username must be able to create and drop tables in the database.

The $dbhost argument is optional -- omit it if the database is local.

Note that any pre-existing L<Wiki::Toolkit> indexes stored in the database
will be I<cleared> by this function, so if you have existing data you
probably want to use the C<store> parameter to get it re-indexed.

=cut

sub setup {
    my $dbh = _get_dbh( @_ );

    # Drop FTS indexes if they already exist.
    my $fts = DBIx::FullTextSearch->open($dbh, "_content_and_title_fts");
    $fts->drop if $fts;
    $fts = DBIx::FullTextSearch->open($dbh, "_title_fts");
    $fts->drop if $fts;

    # Set up FullText indexes and index anything already extant.
    my $fts_all = DBIx::FullTextSearch->create($dbh, "_content_and_title_fts",
                         frontend       => "table",
                         backend        => "phrase",
                         table_name     => "node",
                         column_name    => ["name","text"],
                         column_id_name => "name",
                         stemmer        => "en-uk");

    my $fts_title = DBIx::FullTextSearch->create($dbh, "_title_fts",
                         frontend       => "table",
                         backend        => "phrase",
                         table_name     => "node",
                         column_name    => "name",
                         column_id_name => "name",
                         stemmer        => "en-uk");

    my $sql = "SELECT name FROM node";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my ($name, $version) = $sth->fetchrow_array) {
        $fts_title->index_document($name);
        $fts_all->index_document($name);
    }
    $sth->finish;
}

sub _get_dbh {
    return $_[0] if ( ref $_[0] and ref $_[0] eq 'DBI::db' );
    my ($dbname, $dbuser, $dbpass, $dbhost) = @_;
    my $dsn = "dbi:mysql:$dbname";
    $dsn .= ";host=$dbhost" if $dbhost;
    my $dbh = DBI->connect($dsn, $dbuser, $dbpass,
               { PrintError => 1, RaiseError => 1,
                 AutoCommit => 1 } )
        or croak DBI::errstr;
    return $dbh;
}

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002-2004 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Wiki::Toolkit>, L<Wiki::Toolkit::Setup::MySQL>, L<DBIx::FullTextSearch>

=cut

1;
