use strict;
use warnings;

package WebService::Tesco::API;

# ABSTRACT: Web service for the Tesco groceries API

use Any::Moose;
use Any::URI::Escape;

use LWP::Curl;
use URI;
use JSON;
use Data::Dumper;


our $VERSION = '0.01';
our $API_ENDPOINT =
  'http://www.techfortesco.com/groceryapi_b1/restservice.aspx';
our $SECURE_ENDPOINT =
  'https://secure.techfortesco.com/groceryapi_b1/restservice.aspx';
our $USER_AGENT = LWP::Curl->new(user_agent => __PACKAGE__ . '_' . $VERSION);


has 'app_key'       => (is => 'ro', isa => 'Str', required => 1);
has 'developer_key' => (is => 'ro', isa => 'Str', required => 1);

has 'email'    => (is => 'rw', isa => 'Str');
has 'password' => (is => 'rw', isa => 'Str');

has 'debug' => (is => 'ro', isa => 'Bool', default => 0);

has 'url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => $API_ENDPOINT,
);

has 'secure_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => $SECURE_ENDPOINT,
);

has 'session_key' => (is => 'rw', isa => 'Str');


sub get {
    my $self = shift;
    my $args = shift;
    my $urlstring =
      (delete $args->{secure} ? $self->secure_url : $self->url) . '?';
    while (my ($key, $value) = each %{$args}) {
        $urlstring .= "$key=" . uri_escape($value) . '&' if $value;
    }
    chop $urlstring;
    warn $urlstring if $self->debug();

    my $url = URI->new($urlstring);
    my $res = $USER_AGENT->get($url);
    unless ($res) {
        die $res;
    }
    warn $res if $self->debug();

    return JSON->new->utf8->decode($res);
}


sub login {
    my $self = shift;
    my $args = shift;

    my $email    = $args->{email}    || $self->email;
    my $password = $args->{password} || $self->password;

    die 'To login you need to supply email and password'
      unless ($email && $password);
    my $result = $self->get(
        {   command        => 'LOGIN',
            email          => $email,
            password       => $password,
            applicationkey => $self->app_key(),
            developerkey   => $self->developer_key(),
            secure         => 1,
        }
    );

    $self->email($email)       if $args->{email};
    $self->password($password) if $args->{password};

    $self->session_key($result->{SessionKey});

    return $result;
}


sub session_get {
    my $self    = shift;
    my $command = shift;
    my $args    = shift || {};
    die 'You need to log in first' unless $self->session_key();
    return $self->get(
        {   %{$args},
            command    => $command,
            sessionkey => $self->session_key()
        }
    );
}


sub amend_order {
    my $self = shift;
    my $args = shift;
    die 'You need to supply an order number (ordernumber)'
      unless $args->{ordernumber};
    return $self->session_get('AMENDORDER', $args);
}


sub cancel_amend_order {
    return shift->session_get('CANCELAMENDORDER');
}


sub change_basket {
    my $self = shift;
    my $args = shift;
    die 'You need to supply a product id (productid)'
      unless $args->{productid};
    die 'You need to supply changequantity' unless $args->{changequantity};
    $args->{substitution}    ||= 'YES';
    $args->{notesforshopper} ||= '';
    return $self->session_get('CHANGEBASKET', $args);
}


sub choose_delivery_slot {
    my $self = shift;
    my $args = shift;
    die 'You need to supply a delivery slot id (deliveryslotid)'
      unless $args->{deliveryslotid};
    return $self->session_get('CHOOSEDELIVERYSLOT', $args);
}


sub latest_app_version {
    my $self = shift;
    return $self->get(
        {command => 'LATESTAPPVERSION', appkey => $self->app_key()});
}


sub list_delivery_slots {
    return shift->session_get('LISTDELIVERYSLOTS');
}


sub list_basket {
    my $self = shift;
    my $args = shift;
    return $self->session_get('LISTBASKET', $args);
}


sub list_basket_summary {
    my $self = shift;
    my $args = shift;
    return $self->session_get('LISTBASKETSUMMARY', $args);
}


sub list_favourites {
    my $self = shift;
    my $args = shift;
    return $self->session_get('LISTFAVOURITES', $args);
}


sub list_pending_orders {
    return shift->session_get('LISTPENDINGORDERS');
}


sub list_product_categories {
    return shift->session_get('LISTPRODUCTCATEGORIES');
}


sub list_product_offers {
    my $self = shift;
    my $args = shift;
    return $self->session_get('LISTPRODUCTOFFERS', $args);
}


sub list_products_by_category {
    my $self = shift;
    my $args = shift;
    return $self->session_get('LISTPRODUCTSBYCATEGORY', $args);
}


sub product_search {
    my $self = shift;
    my $args = shift;
    return $self->session_get('PRODUCTSEARCH', $args);
}


sub ready_for_checkout {
    return shift->session_get('READYFORCHECKOUT');
}


sub server_date_time {
    return shift->get({command => 'SERVERDATETIME'});
}


sub save_amend_order {
    return shift->session_get('SAVEAMENDORDER');
}

1;


=pod

=head1 NAME

WebService::Tesco::API - Web service for the Tesco groceries API

=head1 VERSION

version 1.110230

=head1 SYNOPSIS

use WebService::Tesco::API;

my $tesco = WebService::Tesco::API->new(
            app_key         => 'xxxxxx',
            developer_key   => 'yyyyyy',
            debug           => 1,
    );

my $result = $tesco->login({
            email       => 'test@test.com',
            password    => 'password',
    });

=head1 DESCRIPTION

Web service for the Tesco groceries API, currently in beta.
Register at: L<https://secure.techfortesco.com/tescoapiweb/>
Terms of use: L<http://www.techfortesco.com/tescoapiweb/terms.htm>

=head1 NAME

WebService::Tesco::API - Web service for the Tesco groceries API.

=head1 VERSION

version 1.110210

=head1 NAME

WebService::Tesco::API - Web service for the Tesco groceries API

=head1 VERSION

Version 0.01

=head1 Constructor

=head2 new()

Creates and returns a new WebService::Tesco::API object

    my $tesco = WebService::Tesco::API->new(
            app_key         => 'xxxxxx',
            developer_key   => 'yyyyyy',
        );

=over 4

=item * C<< app_key => 'xxxxx' >>

Set the application key. This can be set up at:
https://secure.techfortesco.com/tescoapiweb/

=item * C<< developer_key => 'yyyyyy' >>

Set the developer key. This can be set up at:
https://secure.techfortesco.com/tescoapiweb/

=item * C<< email => 'test@test.com' >>

Set the email to log in with, only used for login

=item * C<< password => 'password' >>

Set the password to log in with, only used for login

=item * C<< debug => [0|1] >>

Show debugging information

=back

=head1 METHODS

=head2 get($args)

General method for sending a GET request.
Set $args->{secure} to use the https endpoint (required for certain requests).
You shouldn't need to use this method directly

=head2 login({ email => 'test@test.com', password => 'password' })

Log in to the Tesco Grocery API
It uses the https endpoint to send email and password.
Returns a session key.

=over 4

=item * C<< email => 'test@test.com' >>

Set the email to log in with

=item * C<< password => 'password' >>

Set the password to log in with

=back

Returns:

{   "StatusCode"                => 0,
    "StatusInfo"                => "Command Processed OK",
    "BranchNumber"              => "2431",
    "CustomerId"                => "12592340",
    "CustomerName"              => "Mr Lansley",
    "SessionKey"                => "x38yJTParR282iuQrmvcmgBwLhwhLKJqKj6rcmxYy1WRR4j5me",
    "ChosenDeliverySlotInfo"    => "No delivery slot is reserved." }

=head2 session_get( $args )

General method for sending a GET request that requires a session key.
You shouldn't need to use this method directly

=head2 amend_order({ ordernumber => 1234567 })

Switches the API into ʻAmend Orderʼ Mode

=over 4

=item * C<< ordernumber => 1234567 >>

Order number from list_pending_orders command

=back

=head2 cancel_amend_order()

Cancels any edits to the amended order and returns to the current un-checked-out basket.

=head2 change_basket({ productid => 1234567, changequantity => 2, substitution => 'YES', notesforshopper => 'note' })

Enables products to be added to, removed from, and updated in the current basket.

=over 4

=item * C<< productid => 123456789 >>

9-digit Product ID available in product data returned from search commands

=item * C<< changequantity => 1 >>

A positive or negative value that changes the products in the basket by that quantity, according to these rules:

=over 4

=item * 1) If the product was absent from the basket before that
product was added, it is inserted into the basket at the
requested quantity.

=item * 2) If the product was already in the basket, the quantity is
increased by requested quantity if positive, or reduced by
the requested quantity if the requested quantity is negative.

=item * 3) If a negative requested quantity is equal to or larger than
the existing quantity, the product is removed from the
basket.

=item * 4) For products that sell by weight, quantities added or
removed are still each. For example, if you are adding apples that are priced per Kg,
selecting 2 for this parameter will add 2 individual apples to the basket, not 2 Kg of apples.

=back

=item * C<< substitution => ['YES'|'NO'] >>

The allowed values are: YES (substitute with anything reasonable) , NO (do not substitute)

=item * C<< notesforshopper => 'I want a turnip shaped like a thingy' >>

A short description to help the shopper choose something appropriate. Try to keep this below 50 characters.

=back

=head2 choose_delivery_slot( deliveryslotid => 1234567 })

Selects a delivery slot from a list provided by list_delivery_slots.

=over 4

=item * C<< deliveryslotid => 1234567 >>

Delivery slot id from list_delivery_slots command.

=back

=head2 latest_app_version()

Returns your app's latest version (set by you in the developer portal).

=head2 list_delivery_slots()

Lists available delivery slots.

=head2 list_basket({ fast => 'Y' })

Lists the contents of the basket.

=over 4

=item * C<< fast => ['Y'|'N'] >>

Massively speeds up retrieval (if set to 'Y') of the basket at the cost of not being able
to find all of the core attributes required for a product, such as EANBarcode. (OPTIONAL)

=back

=head2 list_basket_summary({ includeproducts => 'Y' })

Lists just summary information about the basket.

=over 4

=item * C<< includeproducts => ['Y'|'N'] >>

includeproducts=N if you only wish to retrieve the basket header information. (OPTIONAL)

=back

=head2 list_favourites({ page => 1 })

Returns the products in the customerʼs favourites list.

=over 4

=item * C<< page => 1 >>

Used to get a page of favourites rather than all of them (the customer may have hundreds!). (OPTIONAL)

=back

=head2 list_pending_orders()

Lists orders that have already been checked-out but not yet delivered.

=head2 list_product_categories()

Lists the departments, aisles and shelves in a nested format.

=head2 list_product_offers({ page => 1 })

Lists all the products currently on offer.

=over 4

=item * C<< page => 1 >>

Used to get a page of offers rather than all of them. (OPTIONAL)

=back

=head2 list_products_by_category({ category => 18, extendedinfo => 'Y' })

Lists the products for a given shelf (provided by list_product_categories).

=over 4

=item * C<< extendedinfo => ['Y'|'N'] >>

Set to 'Y' for extended information. (OPTIONAL)

=back

=head2 product_search({ searchtext => 'Turnip', extendedinfo => 'Y' })

Searches for products using text or barcode.

=over 4

=item * C<< searchtext => 'Turnip' >>

Text to search for products, 9-digit Product ID, or 13-digit numeric barcode value.

=item * C<< extendedinfo => ['Y'|'N'] >>

Set to 'Y' for extended information. (OPTIONAL)

=back

=head2 ready_for_checkout()

Checks to see if an order is ready for checkout (that is, there are at least 5 products
in the basket and a delivery slot has been selected).

=head2 server_date_time()

Returns the serverʼs current date and time.

=head2 save_amend_order()

The API is requested to save changes to the amended order.

=head1 AUTHOR

Willem Basson <willem.basson@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Willem Basson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Willem Basson <willem.basson@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Willem Basson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
