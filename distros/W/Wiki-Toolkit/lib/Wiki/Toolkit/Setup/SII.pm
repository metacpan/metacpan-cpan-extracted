package Wiki::Toolkit::Setup::SII;

use strict;

use vars qw( $VERSION );
$VERSION = '0.03';

use DBI;
use Search::InvertedIndex;
use Wiki::Toolkit::Search::SII;
use Carp;

=head1 NAME

Wiki::Toolkit::Setup::SII - Set up Search::InvertedIndex indexes for Wiki::Toolkit

=head1 SYNOPSIS

  use Wiki::Toolkit::Setup::SII;
  my $indexdb = Search::InvertedIndex::DB::Mysql->new(
                   -db_name    => $dbname,
                   -username   => $dbuser,
                   -password   => $dbpass,
           -hostname   => '',
                   -table_name => 'siindex',
                   -lock_mode  => 'EX' );
  Wiki::Toolkit::Setup::SII::setup( indexdb => $indexdb );

=head1 DESCRIPTION

Set up L<Search::InvertedIndex> indexes for use with L<Wiki::Toolkit.> Has
only one function, C<setup>, which takes one mandatory argument,
C<indexdb>, the C<Search::InvertedIndex::DB::*> object to use as the
backend, and one optional argument, C<store>, a C<Wiki::Toolkit::Store::*
object> corresponding to existing data that you wish to (re-)index.

Note that any pre-existing L<Wiki::Toolkit> indexes stored in C<indexdb>
will be I<cleared> by this function, so if you have existing data you
probably want to use the C<store> parameter to get it re-indexed.

=cut

sub setup {
    my %args = @_;
    my $indexdb = $args{indexdb};
    croak "Must supply indexdb" unless $indexdb;

    # Drop indexes if they already exist.
    $indexdb->open;
    $indexdb->clear;
    $indexdb->close;

    # If we've been passed a store, index all its data.
    my $store = $args{store};
    if ( $store ) {
        my @nodes = $store->list_all_nodes;
        my $search = Wiki::Toolkit::Search::SII->new( indexdb => $indexdb );
        foreach my $node ( @nodes ) {
            my $content = $store->retrieve_node( $node );
            $search->index_node( $node, $content );
        }
    }
}

=head1 AUTHOR

Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2002 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Wiki::Toolkit>, L<Wiki::Toolkit::Setup::MySQL>, L<DBIx::FullTextSearch>

=cut

1;
