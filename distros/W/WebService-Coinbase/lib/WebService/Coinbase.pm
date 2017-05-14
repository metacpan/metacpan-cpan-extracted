package WebService::Coinbase;
use Moose;
with 'WebService::Client';

use Crypt::Mac::HMAC qw(hmac hmac_hex);
use Function::Parameters;
use HTTP::Request::Common qw(DELETE GET POST PUT);
use Time::HiRes qw(time);

has api_key => (
    is       => 'ro',
    required => 1,
);

has api_secret => (
    is       => 'ro',
    required => 1,
);

has '+base_url' => (
    is      => 'ro',
    default => 'https://api.coinbase.com/v1',
);

sub BUILD {
    my ($self) = @_;
    $self->ua->default_header(':ACCESS_KEY' => $self->api_key);
}

around req => fun($orig, $self, $req, @rest) {
    my $nonce = time * 1e5;
    my $signature =
        hmac_hex 'SHA256', $self->api_secret, $nonce, $req->uri, $req->content;
    $req->header(':ACCESS_NONCE'     => $nonce);
    $req->header(':ACCESS_SIGNATURE' => $signature);
    return $self->$orig($req, @rest);
};

method get_accounts { $self->get('/accounts') }

method get_account($id) { $self->get("/accounts/$id") }

method create_account(HashRef $data) {
    return $self->post("/accounts", { account => $data });
}

method modify_account($id, HashRef $data) {
    return $self->put("/accounts/$id", { account => $data });
}

method get_balance { $self->get('/account/balance') }

method get_account_balance($id) { $self->get("/accounts/$id/balance") }

method get_account_address($id) { $self->get("/accounts/$id/address") }

method create_account_address($id, HashRef $data) {
    return $self->post("/accounts/$id/address", { address => $data });
}

method get_primary_account { $self->get("/accounts/primary") }

method set_primary_account($id) { $self->post("/accounts/$id/primary") }

method delete_account($id) { $self->delete("/accounts/$id") }

method get_addresses { $self->get("/addresses") }

method get_address($id) { $self->get("/addresses/$id") }

method get_contacts { $self->get('/contacts') }

method get_transactions { $self->get('/transactions') }

method get_transaction($id) { $self->get("/transactions/$id") }

method send_money($data) {
    return $self->post('/transactions/send_money', { transaction => $data });
}

method transfer_money($data) {
    return $self->post('/transactions/transfer_money',{ transaction => $data });
}

method request_money($data) {
    return $self->post('/transactions/request_money', { transaction => $data });
}

method resend_request($id) {
    return $self->put("/transactions/$id/resend_request");
}

method complete_request($id) {
    return $self->put("/transactions/$id/complete_request");
}

method cancel_request($id) {
    return $self->put("/transactions/$id/cancel_request");
}

method get_buy_price(Maybe[HashRef] :$query) {
    return $self->get("/prices/buy", $query);
}

method get_sell_price(Maybe[HashRef] :$query) {
    return $self->get("/prices/sell", $query);
}

method get_spot_price(Maybe[HashRef] :$query) {
    return $self->get("/prices/spot_rate", $query);
}

method get_orders { $self->get('/orders') }

method create_order(HashRef $data) {
    return $self->post('/orders', { button => $data });
}

method get_order($id) { $self->get("/orders/$id") }

method refund_order($id, HashRef $data) {
    return $self->post("/orders/$id", { order => $data });
}

# ABSTRACT: Coinbase (http://coinbase.com) API bindings


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Coinbase - Coinbase (http://coinbase.com) API bindings

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

    use WebService::Coinbase;

    my $coin = WebService::Coinbase->new(
        api_key    => 'API_KEY',
        api_secret => 'API_SECRET',
        logger     => Log::Tiny->new('/tmp/coin.log'), # optional
    );
    my $accounts = $coin->get_accounts();

=head1 METHODS

=head2 get_accounts

    get_accounts()

Returns the user's active accounts.

=head2 get_account

    get_account($account_id)

Returns one of the user's active accounts.

=head2 get_primary_account

    get_primary_account()

Returns the user's primary account.

=head2 set_primary_account

    set_primary_account($account_id)

Sets the primary account.

=head2 create_account

    create_account($data)

Creates a new account for the user.

Example:

    my $account = $coin->create_account({ name => "Bling Bling" });

=head2 get_balance

    get_balance()

Returns the user's current balance.

=head2 get_account_balance

    get_account_balance($account_id)

Returns the current balance for the given account.

=head2 get_account_address

    get_account_address($account_id)

Returns the user's current bitcoin receive address.

=head2 create_account_address

    create_account_address($account_id, $data)

Generates a new bitcoin receive address for the user.

Example:

    $coin->create_account_address($account_id, {
        label        => 'college fund',
        callback_url => 'http://foo.com/bar',
    });

=head2 modify_account

    modify_account($account_id, $data)

Modifies an account.

Example:

    $coin->modify_account($acct_id, { name => "Kanye's Account" });

=head2 delete_account

    delete_account($account_id)

Deletes an account.
Only non-primary accounts with zero balance can be deleted.

=head2 get_addresses

    get_addresses()

Returns the bitcoin addresses a user has associated with their account.

=head2 get_address

    get_address($id_or_address)

Returns the bitcoin address object for the given id or address.

=head2 get_contacts

    get_contacts()

Returns contacts the user has previously sent to or received from.

=head2 get_transactions

    get_transactions()

Returns the user's transactions sorted by created_at in descending order.

=head2 get_transaction

    get_transaction($transaction_id)

Returns the transaction for the given id.

=head2 send_money

    send_money($data)

Send money to an email or bitcoin address.

Example:

    $coin->send_money({
        to       => $email_or_bitcoin_address,
        amount   => '1.23',
        notes    => 'Here is your money',
    });

=head2 transfer_money

    transfer_money($data)

Transfer bitcoin between accounts.

=head2 request_money

    request_money($data)

Request money from an email.

=head2 resend_request

    resend_request($transaction_id)

Resend a money request.

=head2 complete_request

    complete_request($transaction_id)

Lets the recipient of a money request complete the request by sending money to
the user who requested the money.
This can only be completed by the user to whom the request was made,
not the user who sent the request.

=head2 cancel_request

    cancel_request($transaction_id)

Cancel a money request.

=head2 get_buy_price

    get_buy_price()
    get_buy_price(query => { qty => 1 })

=head2 get_sell_price

    get_sell_price()
    get_sell_price(query => { qty => 1 })

=head2 get_spot_price

    get_spot_price()
    get_spot_price(query => { currency  => 'CAD' })

=head2 get_orders

    get_orders()

Returns a merchant's orders that they have received.

=head2 create_order

    create_order($data)

Returns an order for a new button.

Example:

    $coin->create_order({
        name               => 'test',
        price_string       => '1.23',
        price_currency_iso => 'BTC',
    });

=head2 get_order

    get_order($order_id)

Returns order details.

=head2 refund_order

    refund_order($order_id, $data)

Refunds an order.

Example:

    $coin->refund_order($order_id, { refund_iso_code => 'BTC' })

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
