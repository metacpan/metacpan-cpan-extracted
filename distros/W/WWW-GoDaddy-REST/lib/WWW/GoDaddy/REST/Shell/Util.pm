package WWW::GoDaddy::REST::Shell::Util;

use strict;
use warnings;

use Sub::Exporter -setup => { exports => [qw(get_resource_by_schema_or_uri)] };

sub get_resource_by_schema_or_uri {
    my ( $self, $schema_or_uri, $id ) = @_;

    my $client = $self->client;

    if ( !defined $schema_or_uri ) {
        die("schema or uri is required");
    }

    my $resource;
    if ( $schema_or_uri =~ /\// ) {
        return $client->http_request_as_resource( 'GET', $schema_or_uri );
    }
    else {
        my $schema = $client->schema($schema_or_uri);
        if ( !$schema ) {
            die("'$schema_or_uri' is not a recognized schema");
        }

        if ( !$schema->is_queryable ) {
            die("This schema has no 'collection' link. It does not look like it can be queried.  You can always try using a direct URL as a way around this if you know a URL exists to query this."
            );
        }

        if ( !defined $id ) {
            die("'id' is required");
        }

        return $resource = eval { $client->query_by_id( $schema_or_uri, $id ); };
    }

}

1;

=head1 AUTHOR

David Bartle, C<< <davidb@mediatemple.net> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2014 Go Daddy Operating Company, LLC

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

=cut
