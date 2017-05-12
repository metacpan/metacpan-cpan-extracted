package Wiki::Toolkit::Search::Lucy;

use strict;

use Lucy::Analysis::PolyAnalyzer;
use Lucy::Index::Indexer;
use Lucy::Index::PolyReader;
use Lucy::Plan::FullTextType;
use Lucy::Plan::Schema;
use Lucy::Search::IndexSearcher;
use Lucy::Search::QueryParser;

use vars qw( @ISA $VERSION );

$VERSION = '0.03';
use base 'Wiki::Toolkit::Search::Base';

=head1 NAME

Wiki::Toolkit::Search::Lucy - Use Lucy to search your Wiki::Toolkit wiki.

=head1 SYNOPSIS

  my $search = Wiki::Toolkit::Search::Lucy->new( path => "/var/lucy/wiki" );
  my %wombat_nodes = $search->search_nodes( "wombat" );

Provides L<Lucy>-based search methods for L<Wiki::Toolkit>.

=cut

=head1 METHODS

=over 4

=item B<new>

  my $search = Wiki::Toolkit::Search::Lucy->new(
      path => "/var/lucy/wiki",
      metadata_fields => [ "category", "locale", "address" ],
      boost => { title => 2.5 },
      content_munger => sub {
                            my $content = shift;
                            $content =~ s/secretword//gs;
                            return $content;
                        },
      node_filter => sub {
                         my %args = @_;
                         return $args{content} =~ /REDIRECT/ ? 0 : 1;
                        },
  );

The C<path> parameter is mandatory. C<path> must be a directory
for storing the indexed data.  It should exist and be writeable.

The other four parameters are optional:

C<metadata_fields> should be a reference to an array of metadata field
names.

C<boost> should be a reference to a hash in which the keys are fields
and the values are numbers - see L<Lucy::Plan::FieldType> for more
info.  Only C<title> is currently supported as a field value.

C<content_munger> should be a reference to a subroutine which takes
the node content as a string and returns another string which will be
indexed in place of the original content.

C<node_filter> should be a reference to a subroutine which takes the
named arguments C<node>, C<content>, and C<metadata> and returns either
true (yes, index this node) or false (no, don't index this node).

Content munging takes place BEFORE node filtering.

=cut

sub _init {
    my ( $self, %args ) = @_;

    # Set up the Lucy schema.  Content and fuzzy title will be indexed but
    # not stored (since we don't need to retrieve them).
    my $schema = Lucy::Plan::Schema->new;
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new( language => "en" );
    my $stored_type = Lucy::Plan::FullTextType->new(
                          analyzer => $polyanalyzer );
    my $unstored_type = Lucy::Plan::FullTextType->new(
                          analyzer => $polyanalyzer, stored => 0 );
    my %title_args = ( analyzer => $polyanalyzer, stored => 1 );
    if ( $args{boost}{title} ) {
        $title_args{boost} = $args{boost}{title};
    }
    my $title_type = Lucy::Plan::FullTextType->new( %title_args );
                          
    $schema->spec_field( name => "content", type => $unstored_type );
    $schema->spec_field( name => "fuzzy",   type => $unstored_type );
    $schema->spec_field( name => "title",   type => $title_type );
    $schema->spec_field( name => "key",     type => $stored_type );

    foreach my $md_field ( @{$args{metadata_fields}} ) {
        $schema->spec_field( name => $md_field, type => $unstored_type );
    }

    $self->{_schema} = $schema;
    $self->{_dir} = $args{path};
    $self->{_metadata_fields} = $args{metadata_fields};
    $self->{_content_munger} = $args{content_munger};
    $self->{_node_filter} = $args{node_filter};
    return $self;
}

sub _dir { shift->{_dir} }
sub _schema { shift->{_schema} }

=item B<index_node>

  $search->index_node( $node, $content, $metadata );

Indexes or reindexes the given node in the search engine indexes. 
You must supply both the node name and its content, but metadata is optional.

If you do supply metadata, it should be a reference to a hash where
the keys are the names of the metadata fields and the values are
either scalars or references to arrays of scalars.  For example:

  $search->index_node( "Calthorpe Arms", "Nice pub in Bloomsbury.",
                       { category => [ "Pubs", "Bloomsbury" ],
                         postcode => "WC1X 8JR" } );

Only those metadata fields which were supplied to ->new will be taken
notice of - others will be silently ignored.

If C<content_munger> has been supplied to C<new> as a subroutine
reference, then C<$content> will be run through this before indexing.

If C<node_filter> has been supplied to C<new> as a subroutine reference,
then this will be used to check whether the node should be indexed or ignored.

Content munging takes place BEFORE node filtering.

=cut

sub index_node {
    my ( $self, $node, $content, $metadata ) = @_;

    # Delete the old version.
    $self->_delete_node( $node );

    # See if we need to munge the content.
    my $munger = $self->{_content_munger};
    if ( $munger && ref $munger eq "CODE" ) {
        $content = &$munger( $content );
    }

    # See if this node should be ignored.
    my $filter = $self->{_node_filter};
    if ( $filter && ref $filter eq "CODE"
         && ! &$filter( node => $node, content => $content,
                        metadata => $metadata ) ) {
        return;
    }

    my $indexer = Lucy::Index::Indexer->new(
        index    => $self->_dir,
        schema   => $self->_schema,
        create   => 1,
        truncate => 0,
    );

    my $key = $self->_make_key( $node );
    my $fuzzy = $self->canonicalise_title( $node );

    my %data = (
        content => join( " ", $node, $content ),
        fuzzy   => $fuzzy,
        title   => $node,
        key     => $key,
    );

    my @fields = @{$self->{_metadata_fields}};
    foreach my $field ( @fields ) {
        my $value = $metadata->{$field};
        if ( $value ) {
            if ( ref $value ) {
                $data{$field} = join( " ", @$value );
            } else {
                $data{$field} = $value;
            }
        }
    }

    $indexer->add_doc( \%data );
    $indexer->commit;
}

sub _delete_node {
    my ( $self, $node ) = @_;

    my $indexer = Lucy::Index::Indexer->new(
        index    => $self->_dir,
        schema   => $self->_schema,
        create   => 1,
        truncate => 0,
    );

    my $key = $self->_make_key( $node );

    $indexer->delete_by_term( field => "key", term => $key );
    $indexer->commit;
}

# We need to make a unique key for when we come to delete a doc - can't just
# delete on title as it does a search rather than an exact match on the field.
sub _make_key {
    my ( $self, $node ) = @_;
    $node =~ s/\s//g;
    return lc( $node );
}

=item B<search_nodes>

  # Find all the nodes which contain the word 'expert'.
  my %results = $search->search_nodes( "expert" );

Returns a (possibly empty) hash whose keys are the node names and
whose values are the scores.

Defaults to AND searches (if C<$and_or> is not supplied, or is anything
other than C<OR> or C<or>).

Searches are case-insensitive.

=cut

sub search_nodes {
    my ( $self, $searchstring, $and_or ) = @_;

    # Bail and return empty list if nothing stored.
    return () unless $self->_index_exists;

    $and_or = uc( $and_or || "" );
    $and_or = "AND" unless $and_or eq "OR";

    my $queryparser = Lucy::Search::QueryParser->new(
        schema         => $self->_schema,
        default_boolop => $and_or,
    );

    my $query = $queryparser->parse( $searchstring );

    my $searcher = Lucy::Search::IndexSearcher->new(
        index => $self->_dir,
    );

    my $num_docs = $searcher->doc_max();
    my $hits = $searcher->hits(
        query      => $query,
        num_wanted => $num_docs,
    );

    my %results;
    while ( my $hit = $hits->next ) {
        $results{ $hit->{title} } = $hit->get_score;
    }
    return %results;
}

# Fuzzy title search - exact match has highest score.
sub _fuzzy_match {
    my ( $self, $string, $canonical ) = @_;

    # Bail and return empty list if nothing stored.
    return () unless $self->_index_exists;

    my $queryparser = Lucy::Search::QueryParser->new(
        schema         => $self->_schema,
        default_boolop => "AND",
    );

    my $query = $queryparser->parse( $canonical );

    my $searcher = Lucy::Search::IndexSearcher->new(
        index => $self->_dir,
    );

    my $num_docs = $searcher->doc_max();
    my $hits = $searcher->hits(
        query      => $query,
        num_wanted => $num_docs,
    );

    my %results;
    while ( my $hit = $hits->next ) {
        $results{ $hit->{title} } = $hit->get_score;
    }
    return map { $_ => ($_ eq $string ? 2 : 1) } keys %results;
}

# Returns true if and only if we have data stored.
sub _index_exists {
    my $self = shift;
    my $reader = Lucy::Index::PolyReader->open( index => $self->_dir );
    return @{ $reader->seg_readers };
}

sub supports_fuzzy_searches { 1; }
sub supports_phrase_searches { 1; }
sub supports_metadata_indexing { 1; }

=back

=head1 SEE ALSO

L<Wiki::Toolkit>, L<Wiki::Toolkit::Search::Base>.

=cut

1;
