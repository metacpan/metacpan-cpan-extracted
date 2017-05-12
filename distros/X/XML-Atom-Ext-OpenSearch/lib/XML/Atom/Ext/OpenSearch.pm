package XML::Atom::Ext::OpenSearch;

use strict;
use warnings;

use base qw( XML::Atom::Base );
use XML::Atom::Feed;

use XML::Atom::Ext::OpenSearch::Query;

our $VERSION = '0.03';

=head1 NAME

XML::Atom::Ext::OpenSearch - XML::Atom extension for OpenSearch data

=head1 SYNOPSIS

    use XML::Atom::Feed;
    use XML::Atom::Ext::OpenSearch;
    
    my $feed = XML::Atom::Feed->new;
    $feed->totalResults( $total );

=head1 DESCRIPTION

This module is an extension to XML::Atom which will let you read and write 
feeds that use OpenSearch data. OpenSearch provides some extra elements
to serialize search results as an Atom feed. See
the specification (http://www.opensearch.org/Specifications/OpenSearch/1.1)
for more information.

=head1 METHODS

=head2 totalResults( $results )

=head2 startIndex( $index )

=head2 itemsPerPage( $items )

=head2 Query( )

In list context, returns all query elements in the document. In scalar
context, returns the first query element found.

=head2 add_Query( $object )

=cut

BEGIN {
    XML::Atom::Feed->mk_elem_accessors(
        qw(totalResults startIndex itemsPerPage),
        [   XML::Atom::Namespace->new(
                "opensearch" => q{http://a9.com/-/spec/opensearch/1.1/}
            )
        ]
    );

    XML::Atom::Feed->mk_object_list_accessor(
        Query => 'XML::Atom::Ext::OpenSearch::Query' );
}

=head2 element_ns( )

Returns the opensearch namespace, C<http://a9.com/-/spec/opensearch/1.1>.

=cut

sub element_ns {
    return XML::Atom::Namespace->new(
        "opensearch" => q{http://a9.com/-/spec/opensearch/1.1/} );
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<XML::Atom>

=back

=cut

1;
