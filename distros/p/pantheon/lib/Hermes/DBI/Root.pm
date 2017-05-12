package Hermes::DBI::Root;

=head1 NAME

Hermes::DBI::Root - DB interface to Hermes root data

=head1 SYNOPSIS

 use Hermes::DBI::Root;

 my $db = Hermes::DBI::Root->new( '/database/file' );

=cut
use strict;
use warnings;

=head1 METHODS

See Vulcan::SQLiteDB.

=cut
use base qw( Vulcan::SQLiteDB );

=head1 DATABASE

A SQLITE db has tables of I<two> columns:

 key : node name
 value : info associated with node

=cut
sub define
{
    key => 'TEXT NOT NULL PRIMARY KEY',
    value => 'BLOB',
};

1;
