package XML::Atom::Ext::OpenSearch::Query;

use strict;
use warnings;

use base qw( XML::Atom::Base );

=head1 NAME

XML::Atom::Ext::OpenSearch::Query - OpenSearch query element

=head1 SYNOPSIS

    my $query = XML::Atom::Ext:OpenSearch::Query->new;
    $query->title( 'foo' );
    $feed->add_Query( $query );

=head1 DESCRIPTION

This elements represents query that was or can be performed by the client. It
can be used to echo the request, or even provide an example query. Review
the specification (http://www.opensearch.org/Specifications/OpenSearch/1.1#OpenSearch_Query_element)
for more information.

=head1 METHODS

=head2 role( $role )

=head2 title( $title )

=head2 totalResults( $total )

=head2 searchTerms( $terms )

=head2 count( $count )

=head2 startIndex( $index )

=head2 startPage( $page )

=head2 language( $language )

=head2 outputEncoding( $encoding )

=head2 inputEncoding( $encoding )

=cut

BEGIN {
    __PACKAGE__->mk_attr_accessors(
        qw(
            role title totalResults searchTerms count startIndex
            startPage language outputEncoding inputEncoding
            )
    );
}

=head2 element_name( )

Returns 'Query'.

=cut

sub element_name {
    return 'Query';
}

=head2 element_ns( )

Returns the opensearch namespace, C<http://a9.com/-/spec/opensearch/1.1>.

=cut

sub element_ns {
    return XML::Atom::Ext::OpenSearch->element_ns;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<XML::Atom::Ext::OpenSearch>

=back

=cut

1;
