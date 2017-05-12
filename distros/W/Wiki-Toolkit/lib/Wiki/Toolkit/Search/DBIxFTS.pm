package Wiki::Toolkit::Search::DBIxFTS;

use strict;
use DBIx::FullTextSearch;
use Carp "croak";
use base 'Wiki::Toolkit::Search::Base';

use vars qw( @ISA $VERSION );

$VERSION = 0.05;

=head1 NAME

Wiki::Toolkit::Search::DBIxFTS - DBIx::FullTextSearch search plugin for Wiki::Toolkit.

=head1 REQUIRES

DBIx::FullTextSearch

=head1 SYNOPSIS

  my $store = Wiki::Toolkit::Store::MySQL->new(
                                    dbname => "wiki", dbpass=>"wiki" );
  my $search = Wiki::Toolkit::Search::DBIxFTS->new( dbh => $store->dbh );
  my %wombat_nodes = $search->search_nodes("wombat");

Provides search-related methods for Wiki::Toolkit.

See also L<Wiki::Toolkit::Search::Base>, for methods not documented here.

=cut

=head1 METHODS

=over 4

=item B<new>

  my $search = Wiki::Toolkit::Search::DBIxFTS->new( dbh => $dbh );

You must supply a handle to a database that has the
DBIx::FullTextSearch indexes already set up. (Currently though there's
no checking that what you supply is even a database handle at all, let
alone one that is compatible with DBIx::FullTextSearch.)

=cut

sub _init {
    my ($self, %args) = @_;
    croak "Must supply a database handle" unless $args{dbh};
    $self->{_dbh} = $args{dbh};
    return $self;
}

# We can't use the base version, since we're doing the analysis
# differently between searching and indexing
sub search_nodes {
    my ($self, $termstr, $and_or) = @_;

    $and_or = uc($and_or);
    unless ( defined $and_or and $and_or eq "OR" ) {
        $and_or = "AND";
    }

    # Extract individual search terms - first phrases (between double quotes).
    my @terms = ($termstr =~ m/"([^"]+)"/g);
    $termstr =~ s/"[^"]*"//g;
    # And now the phrases are gone, just split on whitespace.
    push @terms, split(/\s+/, $termstr);

    # If this is an AND search, tell DBIx::FTS we want every term.
    @terms = map { "+$_" } @terms if $and_or eq "AND";

    # Open and perform the FTS.
    my $dbh = $self->{_dbh};
    my $fts = DBIx::FullTextSearch->open($dbh, "_content_and_title_fts");
    my @finds = $fts->econtains(@terms);

    # Well, no scoring yet, you see.
    return map { $_ => 1 } @finds;
}

sub index_node {
    my ($self, $node) = @_;

    my $dbh = $self->{_dbh};
    my $fts_all = DBIx::FullTextSearch->open($dbh, "_content_and_title_fts");
    my $fts_titles = DBIx::FullTextSearch->open($dbh, "_title_fts");

    $fts_all->index_document($node);
    $fts_titles->index_document($node);

    delete $fts_all->{db_backend}; # hack around buglet in DBIx::FTS
    delete $fts_titles->{db_backend}; # ditto
}

sub delete_node {
    my ($self, $node) = @_;
    my $dbh = $self->{_dbh};
    my $fts_all    = DBIx::FullTextSearch->open($dbh, "_content_and_title_fts")
        or croak "Can't open _content_and_title_fts";
    my $fts_titles = DBIx::FullTextSearch->open($dbh, "_title_fts")
        or croak "Can't open _title_fts";
    eval { $fts_all->delete_document($node); };
    croak "Couldn't delete from full index: $@" if $@;
    eval { $fts_titles->delete_document($node); };
    croak "Couldn't delete from title-only index: $@" if $@;
    return 1;
}

sub supports_phrase_searches { return 1; }
sub supports_fuzzy_searches  { return 0; }

=back

=head1 SEE ALSO

L<Wiki::Toolkit>,  L<Wiki::Toolkit::Search::Base>.

=cut

1;
