package XML::OPDS::OpenSearch::Query;
use strict;
use warnings FATAL => 'all';
use Types::Standard qw/Maybe Str Enum Int/;
use Moo;
use URI::Escape ();

=head1 NAME

XML::OPDS::OpenSearch::Query - OpenSearch query element for XML::OPDS

=head1 DESCRIPTION

This module is mostly an helper to provide validation to create
C<Query> elements in an OPDS search result. Notably, this doesn't
expand to XML.

=head1 SYNOPSIS

use XML::OPDS;
use XML::OPDS::OpenSearch::Query;
use Data::Page;
my $feed = XML::OPDS->new;
my $query = XML::OPDS::OpenSearch::Query->new(role => "example",
                                              searchTerms => "my terms",
                                              );
my $pager = Data::Page->new;
$pager->total_entries(50);
$pager->entries_per_page(20);
$pager->current_page(1);
$feed->search_result_pager($pager);
$feed->search_result_terms('my terms');

# please note that if you set the search_result_pager and
# search_result_terms a role:request query is added automatically, so
# here we add only the example.

$feed->search_result_queries([$query]);
print $feed->render;

=head1 SETTERS/ACCESSORS

All of them are optionals except C<role>.

=head2 role

Role values (from L<http://www.opensearch.org/Specifications/OpenSearch/1.1#Role_values>)

=over 4

=item request

Represents the search query that can be performed to retrieve the same
set of search results.

=item example

Represents a search query that can be performed to demonstrate the search engine. 

=item related

Represents a search query that can be performed to retrieve similar
but different search results.

=item correction

Represents a search query that can be performed to improve the result
set, such as with a spelling correction.

=item subset

Represents a search query that will narrow the current set of search results. 

=item superset

Represents a search query that will broaden the current set of search results.

=back

=cut

has role => (is => 'rw',
             isa => Enum[qw/role request example related correction subset superset/]);

=head2 title

Contains a human-readable plain text string describing the search request.

Restrictions: The value must contain 256 or fewer characters of plain
text. The value must not contain HTML or other markup.

This object stores an arbitrary string, but cut it at 256 when
producing the attributes.

=head2 totalResults

Integer.

Contains the expected number of results to be found if the search request were made. 

=head2 searchTerms

String.

Contains the value representing the "searchTerms" as an OpenSearch 1.1 parameter.

The URI escaping is performed by the module.

=head2 count

Integer.

Replaced with the number of search results per page desired by the search client. 

=head2 startIndex

Integer.

Replaced with the index of the first search result desired by the search client. 

=head2 startPage

Integer.

Replaced with the page number of the set of search results desired by the search client. 

=head2 language

String. The value must conform to the XML 1.0 Language Identification,
as specified by RFC 5646. In addition, a value of "*" will signify
that the search client desires search results in any language.

This module passes it verbatim.

=head2 inputEncoding

The value must conform to the XML 1.0 Character Encodings, as
specified by the IANA Character Set Assignments.

This module passes it verbatim.

=head2 outputEncoding

Same as above.

=head1 METHODS

=head2 attributes_hashref

Return the attributes which are defined in an hashref. The C<title> is
mangled to 256 characters and 

=head1 SEE ALSO

Specification: L<http://www.opensearch.org/Specifications/OpenSearch/1.1>

=cut

has title => (is => 'rw', isa => Maybe[Str]);
has totalResults => (is => 'rw', isa => Maybe[Int]);
has searchTerms => (is => 'rw', isa => Maybe[Str]);
has count => (is => 'rw', isa => Maybe[Int]);
has startIndex => (is => 'rw', isa => Maybe[Int]);
has startPage => (is => 'rw', isa => Maybe[Int]);
has language => (is => 'rw', isa => Maybe[Str]);
has inputEncoding => (is => 'rw', isa => Maybe[Str]);
has outputEncoding => (is => 'rw', isa => Maybe[Str]);

sub attributes_hashref {
    my $self = shift;
    my %out = (role => $self->role);
    if (defined $self->title) {
        $out{title} = substr $self->title, 0, 256;
    }
    if (defined $self->searchTerms) {
        $out{searchTerms} = URI::Escape::uri_escape($self->searchTerms);
    }
    foreach my $accessor (qw/totalResults
                             count
                             startIndex
                             startPage
                             language
                             inputEncoding
                             outputEncoding/) {
        my $v = $self->$accessor;
        if (defined $v) {
            $out{$accessor} = $v;
        }
    }
    return \%out;
}

1;
