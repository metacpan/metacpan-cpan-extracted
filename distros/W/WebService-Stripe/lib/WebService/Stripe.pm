package WebService::Stripe;
use Moo;
with 'WebService::Client';

our $VERSION = '1.0300'; # VERSION

use Carp qw(croak);
use HTTP::Request::Common qw( POST );
use Method::Signatures;
use Data::NestedParams;
use constant {
    FILE_UPLOADS_URL         => 'https://uploads.stripe.com/v1/files',
    FILE_PURPOSE_ID_DOCUMENT => 'identity_document',
    MARKETPLACES_MIN_VERSION => '2014-11-05',
};

has api_key => (
    is       => 'ro',
    required => 1,
);

has '+serializer' => (
    default  => sub {
        sub {
            my ($data, %args) = @_;
            return collapse_nested_params($data);
        }
    }
);

has version => (
    is      => 'ro',
    default => MARKETPLACES_MIN_VERSION,
);

has '+base_url' => ( default => 'https://api.stripe.com' );

has '+content_type' => ( default => 'application/x-www-form-urlencoded' );

method BUILD(@args) {
    $self->ua->default_headers->authorization_basic( $self->api_key, '' );
    $self->ua->default_header( 'Stripe-Version' => $self->version );
}

method next(HashRef $thing, HashRef :$query, HashRef :$headers) {
    $query ||= {};
    return undef unless $thing->{has_more};
    my $starting_after = $thing->{data}[-1]{id} or return undef;
    return $self->get( $thing->{url},
        { %$query, starting_after => $starting_after }, headers => $headers );
}

method create_customer(Maybe[HashRef] $data, :$headers) {
    return $self->post( "/v1/customers", $data, headers => $headers );
}

method create_recipient(HashRef $data, :$headers) {
    return $self->post( "/v1/recipients", $data, headers => $headers );
}

method get_recipient(Str $id, :$headers) {
    return $self->get( "/v1/recipients/$id", {}, headers => $headers );
}

method get_application_fee(Str $id, :$headers) {
    return $self->get( "/v1/application_fees/$id", {}, headers => $headers );
}

method get_balance(:$headers) {
    return $self->get( "/v1/balance", {}, headers => $headers );
}

method get_customer(Str $id, :$headers) {
    return $self->get( "/v1/customers/$id", {}, headers => $headers );
}

method update_customer(Str $id, HashRef :$data!, :$headers) {
    return $self->post( "/v1/customers/$id", $data, headers => $headers );
}

method get_customers(HashRef :$query, :$headers) {
    return $self->get( "/v1/customers", $query, headers => $headers );
}

method create_card(HashRef $data, :$customer_id!, :$headers) {
    return $self->post(
        "/v1/customers/$customer_id/cards", $data, headers => $headers );
}

method get_charge(HashRef|Str $charge, :$query, :$headers) {
    $charge = $charge->{id} if ref $charge;
    return $self->get( "/v1/charges/$charge", $query, headers => $headers );
}

method create_charge(HashRef $data, :$headers) {
    return $self->post( "/v1/charges", $data, headers => $headers );
}

method update_charge(HashRef|Str $charge, HashRef :$data!, :$headers) {
    $charge = $charge->{id} if ref $charge;
    return $self->post( "/v1/charges/$charge", $data, headers => $headers );
}

method capture_charge(Str $id, HashRef :$data, :$headers) {
    return $self->post( "/v1/charges/$id/capture", $data, headers => $headers );
}

method refund_charge(Str $id, HashRef :$data, :$headers) {
    return $self->post( "/v1/charges/$id/refunds", $data, headers => $headers );
}

method refund_app_fee(Str $fee_id, HashRef :$data, :$headers) {
    my $url = "/v1/application_fees/$fee_id/refunds";
    return $self->post( $url, $data, headers => $headers );
}

method add_source(HashRef|Str $cust, HashRef $data, :$headers) {
    $cust = $cust->{id} if ref $cust;
    return $self->post( "/v1/customers/$cust/sources", $data, headers => $headers );
}

method create_token(HashRef $data, :$headers) {
    return $self->post( "/v1/tokens", $data, headers => $headers );
}

method get_token(Str $id, :$headers) {
    return $self->get( "/v1/tokens/$id", {}, headers => $headers );
}

method create_account(HashRef $data, :$headers) {
    return $self->post( "/v1/accounts", $data, headers => $headers );
}

method get_account(Str $id, :$headers) {
    return $self->get( "/v1/accounts/$id", {}, headers => $headers );
}

method get_platform_account(:$headers) {
    return $self->get( "/v1/account", {}, headers => $headers );
}

method update_account(Str $id, HashRef :$data!, :$headers) {
    return $self->post( "/v1/accounts/$id", $data, headers => $headers );
}

method upload_identity_document(HashRef|Str $account_id, Str $filepath) {
    return $self->req(
        POST FILE_UPLOADS_URL,
        Stripe_Account => ( ref $account_id ? $account_id->{id}: $account_id ),
        Content_Type   => 'form-data',
        Content        => [
            purpose => FILE_PURPOSE_ID_DOCUMENT,
            file    => [ $filepath ],
        ],
    );
}

method add_bank(HashRef $data, Str :$account_id!, :$headers) {
    return $self->post(
        "/v1/accounts/$account_id/bank_accounts", $data, headers => $headers );
}

method update_bank(Str $id, Str :$account_id!, HashRef :$data!, :$headers) {
    return $self->post( "/v1/accounts/$account_id/bank_accounts/$id", $data,
        headers => $headers );
}

method delete_bank(Str $id, Str :$account_id!, :$headers) {
    return $self->delete(
        "/v1/accounts/$account_id/bank_accounts/$id", headers => $headers );
}

method get_banks(Str :$account_id!, :$headers) {
    return $self->get(
        "/v1/accounts/$account_id/bank_accounts", {}, headers => $headers );
}

method create_transfer(HashRef $data, :$headers) {
    return $self->post( "/v1/transfers", $data, headers => $headers );
}

method get_transfer(Str $id, :$headers) {
    return $self->get( "/v1/transfers/$id", {}, headers => $headers );
}

method get_transfers(HashRef :$query, :$headers) {
    return $self->get( "/v1/transfers", $query, headers => $headers );
}

method update_transfer(Str $id, HashRef :$data!, :$headers) {
    return $self->post( "/v1/transfers/$id", $data, headers => $headers );
}

method cancel_transfer(Str $id, :$headers) {
    return $self->post("/v1/transfers/$id/cancel", undef, headers => $headers);
}

method reverse_transfer($xfer_id, HashRef :$data = {}, HashRef :$headers = {}) {
    return $self->post("/v1/transfers/$xfer_id/reversals", $data,
        headers => $headers,
    );
}

# keep create_reversal for backwards compatibility
*create_reversal = \&reverse_transfer;

method get_bitcoin_receivers(HashRef :$query, :$headers) {
    return $self->get( "/v1/bitcoin/receivers", $query, headers => $headers );
}

method create_bitcoin_receiver(HashRef $data, :$headers) {
    return $self->post( "/v1/bitcoin/receivers", $data, headers => $headers );
}

method get_bitcoin_receiver(Str $id, :$headers) {
    return $self->get( "/v1/bitcoin/receivers/$id", {}, headers => $headers );
}

method get_events(HashRef :$query, :$headers) {
    return $self->get( "/v1/events", $query, headers => $headers );
}

method get_event(Str $id, :$headers) {
    return $self->get( "/v1/events/$id", {}, headers => $headers );
}

method create_access_token(HashRef $data, :$headers) {
    my $url = "https://connect.stripe.com/oauth/token";
    return $self->post( $url, $data, headers => $headers );
}

# ABSTRACT: Stripe API bindings


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Stripe - Stripe API bindings

=head1 VERSION

version 1.0300

=head1 SYNOPSIS

    my $stripe = WebService::Stripe->new(
        api_key => 'secret',
        version => '2014-11-05', # optional
    );
    my $customer = $stripe->get_customer('cus_57eDUiS93cycyH');

=head1 TESTING

Set the PERL_STRIPE_TEST_API_KEY environment variable to your Stripe test
secret, then run tests as you normally would using prove.

=head1 HEADERS

WebService::Stripe supports passing custom headers to any API request by passing a hash of header values as the optional C<headers> named parameter:

    $stripe->create_charge({ ... }, headers => { stripe_account => "acct_123" })

Note that header names are normalized: C<foo_bar>, C<Foo-Bar>, and C<foo-bar> are equivalent.

Three headers stand out in particular:

=over

=item Stripe-Version

This indicates the version of the Stripe API to use. If not given, we default to C<2014-11-05>, which is the earliest version of the Stripe API to support marketplaces.

=item Stripe-Account

This specifies the ID of the account on whom the request is being made. It orients the Stripe API around that account, which may limit what records or actions are able to be taken. For example, a `get_card` request will fail if given the ID of a card that was not associated with the account.

=item Idempotency-Key

All POST methods support idempotent requests through setting the value of an Idempotency-Key header. This is useful for preventing a request from being executed twice, e.g. preventing double-charges. If two requests are issued with the same key, only the first results in the creation of a resource; the second returns the latest version of the existing object.

This feature is in ALPHA and subject to change without notice. Contact Stripe to confirm the latest behavior and header name.

=back

=head1 METHODS

=head2 get_customer

    get_customer($id)

Returns the customer for the given id.

=head2 create_customer

    create_customer($data)

Creates a customer.
The C<$data> hashref is optional.
Returns the customer.

Example:

    $customer = $stripe->create_customer({ email => 'bob@foo.com' });

=head2 update_customer

    update_customer($id, data => $data)

Updates a customer.
Returns the updated customer.

Example:

    $customer = $stripe->update_customer($id, data => { description => 'foo' });

=head2 get_customers

    get_customers(query => $query)

Returns a list of customers.
The query param is optional.

=head2 next

    next($collection)

Returns the next page of results for the given collection.

Example:

    my $customers = $stripe->get_customers;
    ...
    while ($customers = $stripe->next($customers)) {
        ...
    }

=head2 create_recipient

    create_recipient($data)

Creates a recipient.
The C<$data> hashref is required and must contain at least C<name> and
C<type> (which can be C<individual> or C<corporate> as per Stripe's
documentation), but can contain more (see Stripe Docs).
Returns the recipient.

Example:

    $recipient = $stripe->create_recipient({
        name => 'John Doe',
        type => 'individual,
    });

=head2 get_recipient

    get_recipient($id)

Retrieves a recipient by id.
Returns the recipient.

Example:

    $recipient = $stripe->get_recipient('rcp_123');

=head2 create_card

    create_card($data, customer_id => 'cus_123')

=head2 get_charge

    get_charge($id, query => { expand => ['customer'] })

Returns the charge for the given id. The optional :$query parameter allows
passing query arguments. Passing an arrayref as a query param value will expand
it into Stripe's expected array format.

=head2 create_charge

    create_charge($data)

Creates a charge.

=head2 capture_charge

    capture_charge($id, data => $data)

Captures the charge with the given id.
The data param is optional.

=head2 refund_charge

    refund_charge($id, data => $data)

Refunds the charge with the given id.
The data param is optional.

=head2 refund_app_fee

    refund_app_fee($fee_id, data => $data)

Refunds the application fee with the given id.
The data param is optional.

=head2 update_charge

    update_charge($id, data => $data)

Updates an existing charge object.

=head2 add_source

    add_source($cust_id, $card_data)

Adds a new funding source (credit card) to an existing customer.

=head2 get_token

    get_token($id)

=head2 create_token

    create_token($data)

=head2 get_account

    get_account($id)

=head2 create_account

    create_account($data)

=head2 update_account

    update_account($id, data => $data)

=head2 get_platform_account

    get_platform_account($id)

=head2 upload_identity_document

Uploads a photo ID to an account.

Example:

    my $account = $stripe->create_account({
        managed => 'true',
        country => 'CA',
    });

    my $file = $stripe->upload_identity_document( $account, '/tmp/photo.png' );
    $stripe->update_account( $account->{id}, data => {
        legal_entity[verification][document] => $file->{id},
    });

=head2 add_bank

    add_bank($data, account_id => $account_id)

Add a bank to an account.

Example:

    my $account = $stripe->create_account({
        managed => 'true',
        country => 'CA',
    });

    my $bank = $stripe->add_bank(
        {
            'bank_account[country]'        => 'CA',
            'bank_account[currency]'       => 'cad',
            'bank_account[routing_number]' => '00022-001',
            'bank_account[account_number]' => '000123456789',
        },
        account_id => $account->{id},
    );

    # or add a tokenised bank

    my $bank_token = $stripe->create_token({
        'bank_account[country]'        => 'CA',
        'bank_account[currency]'       => 'cad',
        'bank_account[routing_number]' => '00022-001',
        'bank_account[account_number]' => '000123456789',
    });

    $stripe->add_bank(
        { bank_account => $bank_token->{id} },
        account_id => $account->{id},
    );

=head2 update_bank

    update_bank($id, account_id => $account_id, data => $data)

=head2 create_transfer

    create_transfer($data)

=head2 get_transfer

    get_transfer($id)

=head2 get_transfers

    get_transfers(query => $query)

=head2 update_transfer

    update_transfer($id, data => $data)

=head2 cancel_transfer

    cancel_transfer($id)

=head2 reverse_transfer

Reverses an existing transfer.

L<Stripe Documentation|https://stripe.com/docs/api/python#transfer_reversals>

Example:

    $ws_stripe->reverse_transfer(
        # Transfer ID (required)
        $xfer_id,
        data => {
            # POST data (optional)
            refund_application_fee        => 'true',
            amount                        => 100,
            description                   => 'Invoice Correction',
            'metadata[local_reversal_id]' => 'rvrsl_123',
            'metadata[requester]'         => 'John Doe'
        },
        headers => {
            # Headers (optional)
            stripe_account => $account->{'id'}
        }
    );

=head2 get_balance

    get_balance()

=head2 get_bitcoin_receivers

    get_bitcoin_receivers()

=head2 create_bitcoin_receiver

    create_bitcoin_receiver($data)

Example:

    my $receiver = $stripe->create_bitcoin_receiver({
        amount   => 100,
        currency => 'usd',
        email    => 'bob@tilt.com',
    });

=head2 get_bitcoin_receiver

    get_bitcoin_receiver($id)

=head2 get_event

    get_event($id)

Returns an event for the given id.

=head2 get_events

    get_events(query => $query)

Returns a list of events.
The query param is optional.

=head2 create_access_token

    create_access_token($data)

Creates an access token for the Stripe Connect oauth flow
L<https://stripe.com/docs/connect/reference#post-token>

=head1 AUTHORS

=over 4

=item *

Naveed Massjouni <naveed@vt.edu>

=item *

Dan Schmidt <danschmidt5189@gmail.com>

=item *

Chris Behrens <chris@tilt.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Tilt, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
