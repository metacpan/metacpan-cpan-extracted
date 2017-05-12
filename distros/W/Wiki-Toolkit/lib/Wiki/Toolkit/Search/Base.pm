package Wiki::Toolkit::Search::Base;

use strict;
use Carp "croak";

use vars qw( @ISA $VERSION );

sub _abstract {
    my $who = (caller(1))[3];
    croak "$who is an abstract method which the ".(ref shift).
          " class has not provided";
}

$VERSION = 0.01;

=head1 NAME

Wiki::Toolkit::Search::Base - Base class for Wiki::Toolkit search plugins.

=head1 SYNOPSIS

  my $search = Wiki::Toolkit::Search::XXX->new( @args );
  my %wombat_nodes = $search->search_nodes("wombat");

This class details the methods that need to be overridden by search plugins.

=cut

=head1 METHODS

=head2 C<new>

  my $search = Wiki::Toolkit::Search::XXX->new( @args );

Creates a new searcher. By default the arguments are just passed to
C<_init>, so you may wish to override that instead.

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, %args) = @_;
    @{$self}{keys %args} = values %args;
    return $self;
}

=head2 C<search_nodes>

  # Find all the nodes which contain the word 'expert'.
  my %results = $search->search_nodes('expert');

Returns a (possibly empty) hash whose keys are the node names and
whose values are the scores in some kind of relevance-scoring system I
haven't entirely come up with yet. For OR searches, this could
initially be the number of terms that appear in the node, perhaps.

Defaults to AND searches (if $and_or is not supplied, or is anything
other than C<OR> or C<or>).

Searches are case-insensitive.

=cut

sub search_nodes {
    my ($self, $termstr, $and_or) = @_;

    $and_or = lc($and_or);
    unless ( defined $and_or and $and_or eq "or" ) {
        $and_or = "and";
    }

    # Extract individual search terms.
    my @terms = $self->analyze($termstr);

    return $self->_do_search($and_or, \@terms);
}

sub _do_search { shift->_abstract };

=head2 C<analyze>

    @terms = $self->analyze($string)

Splits a string into a set of terms for indexing and searching. Typically
this is done case-insensitively, splitting at word boundaries, and extracting
words that contain at least 1 word characters.

=cut

sub analyze {
    my ($self, $string) = @_;
    return grep { length > 1            # ignore single characters
                  and ! /^\W*$/ }       # and things composed entirely
                                        # of non-word characters
           split( /\b/,                 # split at word boundaries
                       lc($string)      # be case-insensitive
                );
}

=head2 C<fuzzy_title_match>

  $wiki->write_node( "King's Cross St Pancras", "A station." );
  my %matches = $search->fuzzy_title_match( "Kings Cross St. Pancras" );

Returns a (possibly empty) hash whose keys are the node names and
whose values are the scores in some kind of relevance-scoring system I
haven't entirely come up with yet.

Note that even if an exact match is found, any other similar enough
matches will also be returned. However, any exact match is guaranteed
to have the highest relevance score.

The matching is done against "canonicalised" forms of the search
string and the node titles in the database: stripping vowels, repeated
letters and non-word characters, and lowercasing.

=cut

sub fuzzy_title_match {
    my ($self, $string) = @_;
    my $canonical = $self->canonicalise_title( $string );
    $self->_fuzzy_match($string, $canonical);
}

sub _fuzzy_match { shift->_abstract };

=head2 C<index_node>

  $search->index_node( $node, $content, $metadata );

Indexes or reindexes the given node in the search engine indexes. 
You must supply both the node name and its content, but metadata is
optional.

If you do supply metadata, it will be used if and only if your chosen
search backend supports metadata indexing (see
C<supports_metadata_indexing>).  It should be a reference to a hash
where the keys are the names of the metadata fields and the values are
either scalars or references to arrays of scalars.  For example:

  $search->index_node( "Calthorpe Arms", "Nice pub in Bloomsbury.",
                       { category => [ "Pubs", "Bloomsbury" ],
                         postcode => "WC1X 8JR" } );

=cut

sub index_node {
    my ($self, $node, $content) = @_;
    croak "Must supply a node name" unless $node;
    croak "Must supply node content" unless defined $content;

    # Index the individual words in the node content and title.
    my @keys = $self->analyze("$content $node");
    $self->_index_node($node, $content, \@keys);
    $self->_index_fuzzy($node, $self->canonicalise_title( $node ));
}

sub _index_node  { shift->_abstract };
sub _index_fuzzy { shift->_abstract };

=head2 B<canonicalise_title>

    $fuzzy = $self->canonicalise_title( $ node);

Returns the node title as suitable for fuzzy searching: with punctuation
and spaces removes, vowels removed, and double letters squashed.

=cut

sub canonicalise_title {
    my ($self, $title) = @_;
    return "" unless $title;
    my $canonical = lc($title);
    $canonical =~ s/\W//g;         # remove non-word characters
    $canonical =~ s/[aeiouy]//g;   # remove vowels and 'y'
    $canonical =~ tr/a-z//s;       # collapse doubled (or tripled, etc) letters
    return $canonical;
}

=head2 C<delete_node>

  $search->delete_node($node);

Removes the given node from the search indexes.  NOTE: It's up to you to
make sure the node is removed from the backend store.  Croaks on error.

=cut

sub delete_node {
    my ($self, $node) = @_;
    croak "Must supply a node name" unless $node;
    $self->_delete_node($node);
}

sub _delete_node { shift->_abstract };

=head2 C<supports_phrase_searches>

  if ( $search->supports_phrase_searches ) {
      return $search->search_nodes( '"fox in socks"' );
  }

Returns true if this search backend supports phrase searching, and
false otherwise.

=cut

sub supports_phrase_searches { shift->_abstract };

=head2 C<supports_fuzzy_searches>

  if ( $search->supports_fuzzy_searches ) {
      return $search->fuzzy_title_match("Kings Cross St Pancreas");
  }

Returns true if this search backend supports fuzzy title matching, and
false otherwise.

=cut

sub supports_fuzzy_searches { shift->_abstract };

=head2 C<supports_metadata_indexing>

  if ( $search->supports_metadata_indexing ) {
      print "This search backend indexes metadata as well as content.";
  }

Returns true if this search backend supports metadata indexing, and
false otherwise.

=cut

sub supports_metadata_indexing { 0; };

=head1 SEE ALSO

L<Wiki::Toolkit>

=cut

1;
