package WWW::Billomat;

use 5.010;

use strict;
use warnings;

use Moose;

use URI;
use REST::Client;
use Encode;

use WWW::Billomat::Client;
use WWW::Billomat::Invoice;
use WWW::Billomat::Invoice::Item;

use JSON;

=head1 NAME

WWW::Billomat - API access to Billomat services

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use WWW::Billomat;

    my $billomat = WWW::Billomat->new(
        billomat_id => 'foo',
        api_key => 'blahblah12345678',
    );
    
    my $client = $billomat->get_client(123);
    my $invoice = WWW::Billomat::Invoice->new(
        client_id => $client->id,
        number => 456,
        discount_rate => 50,
    );
    if(not $billomat->create_invoice($invoice)) {
        die "ERROR creating invoice: " . $billomat->response_content();
    }

=cut

has billomat_id => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has api_key => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has rest_client => (
    is => 'rw',
    isa => 'REST::Client',
    lazy_build => 1,
    handles => {
        response_code => 'responseCode',
        response_content => 'responseContent',
        response_headers => 'responseHeaders',
    },
);

has request_body => (
    is => 'rw',
    isa => 'Str',
);

has base_url => (
    is => 'rw',
    isa => 'URI',
    lazy_build => 1,
);

=head1 DESCRIPTION

This module is an interface to the Billomat API, "the simple online
service for quoting, billing and more".

For more information:

=over 4

=item http://www.billomat.com/en/

=item http://www.billomat.com/en/api

=back

Note the implementation is B<partial>. The currently implement feature 
set is:

=over 4

=item * list, create, edit, delete clients

=item * set client properties

=item * list, create, edit, delete invoices

=item * list, create invoice items

=item * complete invoices and get PDF output

=back

=head1 SUBROUTINES/METHODS

B<NOTE>: all methods return either undef or false in case of failure.
To investigate error conditions, three methods are delegated to the
underlying L<REST::Client> object:

=over 4

=item * response_code

=item * response_content

=item * response_headers

=back

Example:

    if(not $billomat->create_invoice($invoice)) {
        die "ERROR creating invoice: " . $billomat->response_content();
    }

=head2 get_clients( [PARAMS] )

Returns an array of L<WWW::Billomat::Client> objects, 
or undef on failure.

See L<WWW::Billomat::Client> for search parameters.

Example:

    my @clients = $billomat->get_clients( name => 'gmbh' );

=cut

sub get_clients {
    my($self, %params) = @_;
    return $self->_search_objects(
        'WWW::Billomat::Client', %params
    );
}

=head2 get_client( ID )

Returns the L<WWW::Billomat::Client> object with the given ID,
or undef on failure.

Example:

    my $client = $billomat->get_client( 123 );

=cut

sub get_client {
    my($self, $id) = @_;
    return $self->_get_object(
        'WWW::Billomat::Client', $id, 
    );
}

=head2 create_client( CLIENT )

Creates a new client. Expects a L<WWW::Billomat::Client> object
as argument.

Returns the created object, or undef on failure.

Example:

    my $client = WWW::Billomat::Client->new(
        name => 'Musterfirma',
        salutation => 'Herr',
        first_name => 'Max',
        last_name => 'Muster',
        # etc.
    );
    if( $billomat->create_client( $client ) ) {
        say "Client created";
    }

=cut

sub create_client {
    my($self, $client) = @_;
    return $self->_create_object($client);
}

=head2 delete_client( CLIENT )

Deletes a client. CLIENT can be either a L<WWW::Billomat::Client>
object, or its ID.

Returns true on success, false on failure.

Example:

    $billomat->delete_client( $client );
    $billomat->delete_client( 123 );

=cut

sub delete_client {
    my($self, $client) = @_;
    return $self->_delete_object(
        'WWW::Billomat::Client', $client
    );
}

=head2 edit_client( CLIENT )

Updates a client with the current CLIENT (L<WWW::Billomat::Client>)
object properties.

Returns true on success, false on failure.

Example:

    my $client = $billomat->get_client( name => 'Foo' );
    $client->name( 'FooBar' );
    $billomat->edit_client($client);

=cut

sub edit_client {
    my($self, $client) = @_;
    return $self->_edit_object($client);
}

=head2 set_client_property( CLIENT, ID, VALUE )

Sets a custom property for a client.

Returns true on success, false on failure.

Example:

    $billomat->set_client_property( $client, 123 => 'foo' );

=cut

sub set_client_property {
    my($self, $client, $id, $value) = @_;
    if(ref $client) {
        $client = $client->id;
    }
    my $body = sprintf(
        '<?xml version="1.0" encoding="UTF-8" ?>'."\n".
        "<client-property-value>".
        "<client_id>%d</client_id>".
        "<client_property_id>%d</client_property_id>".
        "<value>%s</value>".
        "</client-property-value>",
        $client,
        $id,
        $value
    );
    $body = Encode::encode('ASCII', $body, Encode::FB_XMLCREF);
    $self->request_body($body);
    # $body = Encode::encode('utf-8', $body);
    my $response = $self->rest_client->POST(
        "client-property-values",
        $body, 
        { 'Content-Type' => 'application/xml; charset=utf-8' }
    );
    return $response->responseCode() == 201;
}

=head2 get_invoices( [PARAMS] )

Returns an array of L<WWW::Billomat::Invoice> objects, 
or undef on failure.

See L<WWW::Billomat::Invoice> for search parameters.

Example:

    my @invoices = $billomat->get_invoices( client_id => 1 );
    
=cut

sub get_invoices {
    my($self, %params) = @_;
    return $self->_search_objects(
        'WWW::Billomat::Invoice', %params
    );
}

=head2 get_invoice( ID )

Returns the L<WWW::Billomat::Invoice> object with the given ID,
or undef on failure.

Example:

    my $invoice = $billomat->get_invoice( 123 );

=cut

sub get_invoice {
    my($self, $id) = @_;
    return $self->_get_object(
        'WWW::Billomat::Invoice', $id
    );
}

=head2 create_invoice( INVOICE )

Creates a new invoice. Expects a L<WWW::Billomat::Invoice> object
as argument.

Returns the created object, or undef on failure.

Example:

    my $invoice = WWW::Billomat::Invoice->new(
        client_id => 123,
        # etc.
    );
    if( $billomat->create_invoice( $invoice ) ) {
        say "Invoice created";
    }

=cut

sub create_invoice {
    my($self, $invoice) = @_;
    return $self->_create_object($invoice);
}

=head2 delete_invoice( INVOICE )

Deletes an invoice. INVOICE can be either a L<WWW::Billomat::Invoice>
object, or its ID.

Returns true on success, false on failure.

Example:

    $billomat->delete_invoice( $invoice );
    $billomat->delete_invoice( 123 );

=cut

sub delete_invoice {
    my($self, $invoice) = @_;
    return $self->_delete_object(
        'WWW::Billomat::Invoice', $invoice,
    );
}

=head2 edit_invoice( INVOICE )

Updates an invoice with the current INVOICE (L<WWW::Billomat::Invoice>)
object properties.

Returns true on success, false on failure.

Example:

    my $invoice = $billomat->get_invoice( 123 );
    $invoice->due_date( 'yesterday' );
    $billomat->edit_invoice($invoice);

=cut

sub edit_invoice {
    my($self, $client) = @_;
    return $self->_edit_object($client);
}

=head2 complete_invoice( INVOICE, TEMPLATE_ID )

Closes an invoice and generates a PDF for it with the given
TEMPLATE_ID.
INVOICE can be either a L<WWW::Billomat::Invoice> object, or its ID.

Returns true on success, false on failure.

Example:

    die unless $billomat->complete_invoice( $invoice, 123 );

=cut

sub complete_invoice {
    my($self, $invoice, $template_id) = @_;
    my $id = $invoice;
    if(ref $invoice) {
        $id = $invoice->id;
    }    
    my $body = sprintf(
        '<?xml version="1.0" encoding="UTF-8" ?>'."\n".
        "<complete><template_id>%d</template_id></complete>",
        $template_id,
    );
    $body = Encode::encode('ASCII', $body, Encode::FB_XMLCREF);
    $self->request_body($body);
    # $body = Encode::encode('utf-8', $body);
    my $response = $self->rest_client->PUT(
        sprintf(
            "%s/%d/complete",
            WWW::Billomat::Invoice->api_resource, 
            $id,
        ),
        $body, 
        { 'Content-Type' => 'application/xml; charset=utf-8' }
    );
    return $response->responseCode() == 200;
}

=head2 get_invoice_pdf( INVOICE )  

Returns the PDF for an invoice 
(note that you must call L</complete_invoice> first). 
INVOICE can be either a L<WWW::Billomat::Invoice> object, or its ID.

Returns the (binary) PDF data, or undef on failure.

Example:

    if(my $pdf = $billomat->get_invoice_pdf($invoice)) {
        open(my $output, '>', 'foo.pdf');
        binmode($output);
        print $output $pdf;
        close($output);
    }

=cut

sub get_invoice_pdf {
    my($self, $invoice) = @_;

    my $id = $invoice;
    if(ref $invoice) {
        $id = $invoice->id;
    }
    
    my $api = URI->new(sprintf(
        "%s/%d/pdf",
        WWW::Billomat::Invoice->api_resource, 
        $id,
    ));
    $api->query_form( format => 'pdf' );
    my $response = $self->rest_client->GET($api->as_string);
    if($response->responseCode() == 200) {
        return $response->responseContent();
    }
}

=head2 get_invoice_items( INVOICE )

Returns an array of L<WWW::Billomat::Invoice::Item> objects,
or undef on failure.

INVOICE can be either a L<WWW::Billomat::Invoice>
object, or its ID.

Example:

    my @items = $billomat->get_invoice_items( $invoice );

=cut

sub get_invoice_items {
    my($self, $invoice) = @_;
    my $id = $invoice;
    if(ref $invoice) {
        $id = $invoice->id;
    }
    return $self->_search_objects(
        'WWW::Billomat::Invoice::Item', invoice_id => $id,
    );
}

=head2 create_invoice_item( ITEM )

Creates a new invoice item. Expects a L<WWW::Billomat::Invoice::Item> 
object as argument.

Returns the created object, or undef on failure.

Example:

    my $item = WWW::Billomat::Invoice::Item->new(
        invoice_id => 123,
        title => 'Cookies',
        quantity => 1_000,
        unit_price => 0.50,
        # etc.
    );
    if( $billomat->create_invoice_item( $item ) ) {
        say "Invoice item created";
    }

=cut

sub create_invoice_item {
    my($self, $item) = @_;
    return $self->_create_object($item);
}

# private methods

sub _build_rest_client {
    my($self) = @_;

    my $client = REST::Client->new(
        host => $self->base_url->as_string,
    );
    $client->addHeader(
        'X-BillomatApiKey', $self->api_key,
    );
    return $client;
}

sub _build_base_url {
    my($self) = @_;

    my $uri = URI->new(
        sprintf("https://%s.billomat.net", $self->billomat_id)
    );
    $uri->path('/api');
    return $uri;
}

sub _populate_from_xml {
    my($self, $object, $xml) = @_;
    foreach my $attribute ($object->meta->get_all_attributes) {
        my $attr = $attribute->name;
        my $value = $xml->findvalue($attr);
        if($value) {
            $object->$attr($xml->findvalue($attr));
        }
    }
    return $object;
}

sub _search_objects {
    my($self, $class, %params) = @_;
    my %query;
    foreach my $param (@{ $class->search_params }) {
        if(exists $params{$param}) {
            $query{$param} = $params{$param};
        }
    }
    my $api = URI->new($class->api_resource);
    $api->query_form(%query);
    return $self->_get_objects(
        $api->as_string, $class
    );
}

sub _get_objects {
    my($self, $api, $class) = @_;
    
    my $response = $self->rest_client->GET($api);
    if($response->responseCode() == 200) {
        my $dom = $response->responseXpath();
        my $xpath = sprintf('//%s/%s',
            $class->api_container_tag,
            $class->api_item_tag,
        );
        my @nodes = $dom->findnodes($xpath);
        my @objects;
        foreach my $node (@nodes) {
            push(@objects, $self->_populate_from_xml(
                $class->new, $node
            ));
        }
        return @objects;
    } else {
        return undef;
    }
}

sub _get_object {
    my($self, $class, $id) = @_;
    
    my $api = sprintf('%s/%s',
        $class->api_resource,
        $id,
    );	
    my $response = $self->rest_client->GET($api);
    if($response->responseCode() == 200) {
        return $self->_get_object_from_response(
            $response, $class
        );
    } else {
        return undef;
    }
}

sub _get_object_from_response {
    my($self, $response, $class) = @_;
    my $dom = $response->responseXpath();
    my $xpath = $class->api_item_tag;
    my @nodes = $dom->findnodes($xpath);
    if(defined $nodes[0]) {
        return $self->_populate_from_xml(
            $class->new, $nodes[0]
        );
    }
    return undef;
}

sub _create_object {
    my($self, $object) = @_;
    my $body = $self->_to_json($object);
    # warn "BODY=$body\n";
    # $body = Encode::encode('ASCII', $body, Encode::FB_XMLCREF);
    $self->request_body($body);
    my $response = $self->rest_client->POST(
        $object->api_resource, $body, {
            # 'Content-Type' => 'application/xml; charset=utf-8'
            'Content-Type' => 'application/json'
        }
    );
    if($response->responseCode() == 201) {
        return $self->_get_object_from_response(
            $response, $object->meta->name,
        );
    } else {
        return undef;
    }
}

sub _delete_object {
    my($self, $class, $object) = @_;
    if(ref $object) {
        $object = $object->id;
    }
    my $response = $self->rest_client->DELETE(
        $class->api_resource . '/' . $object
    );
    return $response->responseCode() == 200;
}

sub _edit_object {
    my($self, $object) = @_;
    my $body = $self->_to_json($object);
    $self->request_body($body);
    my $response = $self->rest_client->PUT(
        $object->api_resource . '/' . $object->id,
        $body, {
            # 'Content-Type' => 'application/xml; charset=utf-8',
            'Content-Type' => 'application/json',
        }
    );
    return $response->responseCode() == 200;
}

sub _to_xml {
    my($self, $object) = @_;
    my $node_name = $object->api_item_tag;
    my $xml = '<?xml version="1.0" encoding="UTF-8" ?>'."\n";    
    $xml .= "<$node_name>\n";
    foreach my $attribute ($object->meta->get_all_attributes) {
        my $attr = $attribute->name;
        if(defined $object->$attr()) {
            $xml .= sprintf("\t<%s>%s</%s>\n",
                # $attr, Encode::encode_utf8 $object->$attr(), $attr
                $attr, $object->$attr(), $attr
            );
        }
    }
    $xml .= "</$node_name>\n";
    return $xml;
}

sub _to_json {
    my($self, $object) = @_;
    my $node_name = $object->api_item_tag;
    my $json = { $object->api_item_tag => {} };
    foreach my $attribute ($object->meta->get_all_attributes) {
        my $attr = $attribute->name;
        if(defined $object->$attr()) {
            $json->{$object->api_item_tag}->{$attr} = $object->$attr();
        }
    }
    return encode_json $json;
}

=head1 AUTHOR

Aldo Calpini, C<< <dada at perl.it> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-billomat at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Billomat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Billomat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Billomat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Billomat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Billomat>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Billomat/>

=back

=head1 SOURCE

The development version is on github at
L<http://github.com/dada/WWW-Billomat>
and may be cloned from
C<git://github.com/dada/WWW-Billomat.git>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Aldo Calpini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1; # End of WWW::Billomat
