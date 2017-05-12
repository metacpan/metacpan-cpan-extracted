package FTNDB::Nodelist;

use warnings;
use strict;
use Carp qw( croak );

=head1 NAME

FTNDB::Nodelist - Fidonet/FTN Nodelist SQL Database operations.

=head1 VERSION

Version 0.37

=cut

our $VERSION = '0.37';

=head1 DESCRIPTION

FTNDB::Nodelist is a Perl module containing common nodelist related subroutines
for Fidonet/FTN Nodelist related processing on a Nodelist table in an SQL Database. The
SQL database engine is one for which a DBD module exists, defaulting to SQLite.

=head1 EXPORT

The following functions are available in this module:  create_nodelist_table(),
drop_nodelist_table(), create_ftnnode_index(), remove_ftn_domain(),
nodelist_file_info().

=head1 FUNCTIONS

=head2 create_nodelist_table

Syntax:  create_nodelist_table($db_handle, $table_name, $db_type);

Create an FTN Nodelist table in an SQL database being used for Fidonet/FTN
processing, where $db_handle is an existing open database handle, $table_name
is the name of the table to be created, and $db_type is the type of database.

=cut

sub create_nodelist_table {

    my($db_handle, $table_name, $db_type) = @_;

    my $sql_statement = "CREATE TABLE $table_name( ";
    # If DB type is PostgreSQL, use SERIAL; else use INTEGER & AUTOINCREMENT
    if ($db_type eq 'Pg') {
        $sql_statement .= "id   SERIAL PRIMARY KEY NOT NULL, ";
    } else {
        $sql_statement .= "id   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, ";
    }
    $sql_statement .= "type      VARCHAR(6) DEFAULT '' NOT NULL, ";
    $sql_statement .= "zone      SMALLINT  DEFAULT '1' NOT NULL, ";
    $sql_statement .= "net       SMALLINT  DEFAULT '1' NOT NULL, ";
    $sql_statement .= "node      SMALLINT  DEFAULT '1' NOT NULL, ";
    $sql_statement .= "point     SMALLINT  DEFAULT '0' NOT NULL, ";
    $sql_statement .= "region    SMALLINT  DEFAULT '0' NOT NULL, ";
    $sql_statement .= "name      VARCHAR(48) DEFAULT '' NOT NULL, ";
    $sql_statement .= "location  VARCHAR(48) DEFAULT '' NOT NULL, ";
    $sql_statement .= "sysop     VARCHAR(48) DEFAULT '' NOT NULL, ";
    $sql_statement .= "phone     VARCHAR(32) DEFAULT '000-000-000-000' NOT NULL, ";
    $sql_statement .= "baud      CHAR(6) DEFAULT '300' NOT NULL, ";
    $sql_statement .= "flags     VARCHAR(128) DEFAULT ' ' NOT NULL, ";
    $sql_statement .= "domain    VARCHAR(8) DEFAULT 'fidonet' NOT NULL, ";
    $sql_statement .= "ftnyear   SMALLINT  DEFAULT '0' NOT NULL, ";
    $sql_statement .= "yearday   SMALLINT  DEFAULT '0' NOT NULL, ";
    $sql_statement .= "source    VARCHAR(16) DEFAULT 'local' NOT NULL, ";
    $sql_statement .= "updated   TIMESTAMP DEFAULT 'now' NOT NULL ";
    $sql_statement .= ") ";

    $db_handle->do("$sql_statement ") or croak($DBI::errstr);

    return(0);

}

=head2 create_ftnnode_index

Syntax:  create_ftnnode_index($db_handle, $table_name);

Create an index named ftnnode on an FTN Nodelist table in an SQL database being
used for Fidonet/FTN processing, where $db_handle is an existing open database
handle and $table_name is the name of the table that is being indexed.  The
index is created on the following fields:  zone, net, node, point, and domain.

=cut

sub create_ftnnode_index {

    my($db_handle, $table_name) = @_;

    my $sql_statement = "CREATE INDEX ftnnode ";
    $sql_statement .= "ON $table_name (zone,net,node,point,domain,ftnyear,yearday) ";

    $db_handle->do("$sql_statement") or croak($DBI::errstr);

    return(0);

}

=head2 remove_ftn_domain

Syntax:  remove_ftn_domain($db_handle, $table_name, $domain);

Remove all entries for a particular FTN domain from an FTN nodelist table in an SQL
database being used for FTN processing;  where $db_handle is an existing open database
handle and $table_name is the name of the table from which the FTN domain $domain is
being removed.

=cut

sub remove_ftn_domain {

    my($db_handle, $table_name, $domain) = @_;

    my $sql_statement = "DELETE FROM $table_name WHERE domain = '$domain'";

    $db_handle->do("$sql_statement") or croak($DBI::errstr);

    return(0);

}

=head2 nodelist_file_info

Syntax:  %nodelist_info = nodelist_file_info($nodelist_file);

Returns a hash containing the header and other information for a nodelist file
when given the file name and path for an FTN nodelist file. The possible keys
returned in the hash are as follows:

=over 4

=item Year

The four digit year from the nodelist file header line. Defaults to the year
number from the nodelist file time stamp.

=item YearDay

The year day number from the nodelist file header line. Defaults to the file
suffix of the nodelist, which is assumed to be a three digit number.

=item FileYear

The four digit year number from the timestamp of the nodelist file.

=item FileYDay

The year day number from the timestamp of the nodelist file.

=item HeaderLine

The header line (first line) from the nodelist file as a string.

=back

=cut

sub nodelist_file_info {

    my $nodelist_file = shift;

    my (%info, $nl);

    use File::Basename;
    ( $info{'FileName'}, $info{'FileDir'}, $info{'FileSuffix'} ) = fileparse($nodelist_file, qr/[^.]*/);

    use File::stat;
    my $fs = stat($nodelist_file);

    #   year of the converted timestamp is the fifth item
    $info{'FileYear'} = (localtime($fs->mtime))[5] + 1900;
    #   yday of converted timestamp is the seventh item
    $info{'FileYDay'} = (localtime($fs->mtime))[7] + 1;

    # Read in the first line of the nodelist file.
    open $nl, q{<}, $nodelist_file or croak "Cannot open $nodelist_file";
    $info{'HeaderLine'} = <$nl>;
    close $nl;

    #   Year key defaults to the four digit year from the nodelist file timestamp.
    $info{'Year'} = $info{'FileYear'};

    #   YearDay key defaults to the nodelist file suffix.
    $info{'YearDay'} = $info{'FileSuffix'};

    return %info;
}

=head1 EXAMPLES

An example of opening an FTN database, then creating a nodelist table,
loading data to it, then creating an index on it, and the closing
the database:

    use FTNDB::Nodelist;

    my $db_handle = open_ftn_database(\%db_option);
    create_nodelist_table($db_handle, $table_name);
    ...   (Load data to nodelist table)
    create_ftnnode_index($db_handle, $table_name);
    close_ftn_database($db_handle);

=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests via the web interface at
L<https://sourceforge.net/p/ftnpl/ftndb/tickets/>. I will be notified,
and then you'll automatically be notified of progress on your bug
as I make changes.

Note that you can also report any bugs or feature requests to
C<bug-ftndb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ftndb>;
however, the FTN Database application Issue tracker at the
SourceForge project  is preferred.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTNDB::Nodelist


You can also look for information at:

=over 4

=item * FTN Database application issue tracker

L<https://sourceforge.net/p/ftnpl/ftndb/tickets/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ftndb>

=item * Search CPAN

L<http://search.cpan.org/dist/ftndb>

=back

=head1 SEE ALSO

 L<FTN::Database>, L<ftndb-admin>, and L<ftndb-nodelist>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2012 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FTNDB::Nodelist
