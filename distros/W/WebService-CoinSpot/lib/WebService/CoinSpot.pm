#!perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# ABSTRACT: Trade BitCoin, Ethereum, Monero and other CryptoCurrency via CoinSpot

# See also https://www.coinspot.com.au/api

package WebService::CoinSpot;

use Moo;
our $VERSION = '0.002'; # VERSION

use Crypt::Mac::HMAC qw/ hmac_hex /;

use namespace::clean;
with 'WebService::Client';

has '+base_url' => ( default => 'https://www.coinspot.com.au' );
has auth_key => ( is => 'ro' );
has auth_secret => ( is => 'ro' );

sub BUILD {
    my $self = shift;
    $self->ua->default_header(
        'User_Agent'    => sprintf(
            'WebService::CoinSpot %s (perl %s; %s)',
            __PACKAGE__->VERSION,
            $^V, $^O),
    );
}

sub _mkuri {
    my $self = shift;
    my @paths = @_;
    return join '/',
        $self->base_url,
        @paths
}

sub _post {
    my $self = shift;
    my $paths = shift;
    my $postdata = shift || {};
    die "auth_key and auth_secret are required to call this method\n"
        unless ($self->auth_secret and $self->auth_key);
    $postdata->{nonce} = time;
    my $postdatajson = $self->json->encode($postdata);
    my $signature = hmac_hex(
                        'SHA512',
                        $self->auth_secret,
                        $postdatajson
                    );
    my $results = $self->post(
        $self->_mkuri('api', @$paths ),
        $postdata,
        headers => {
            key  => $self->auth_key,
            sign => $signature,
#            Content => $postdatajson,
        }
    );
    return wantarray ? %$results : $results
}


sub latest {
    my $self = shift;
    my $results = $self->get( $self->_mkuri('pubapi', 'latest' ));
    return wantarray ? %$results : $results
}


sub orders {
    my $self = shift;
    my %args = @_;
    return $self->_post(
        ['orders'],
        { ( $args{cointype} ? +(cointype => $args{cointype}) : () ) }
    )
}


sub orders_history {
    my $self = shift;
    my %args = @_;
    return $self->_post(
        [qw/ orders history /],
        { ( $args{cointype} ? +(cointype => $args{cointype}) : () ) }
    )
}


sub balances {
    my $self = shift;
    return $self->_post( [qw/ my balances /] )
}


sub myorders {
    my $self = shift;
    return $self->_post( [qw/ my orders /] )
}


sub quotebuy {
    my $self = shift;
    my %args = @_;
    my %postdata;
    for my $k (qw/ cointype amount /) {
        $postdata{$k} = $args{$k}
            if $args{$k};
    }
    return $self->_post(
        [qw/ quote buy /],
        \%postdata,
    )
}


sub buy {
    my $self = shift;
    my %args = @_;
    my %postdata;
    for my $k (qw/ cointype amount rate /) {
        $postdata{$k} = $args{$k}
            if $args{$k};
    }
    return $self->_post(
        [qw/ my buy /],
        \%postdata,
    )
}


sub cancelbuy {
    my $self = shift;
    my %args = @_;
    return $self->_post(
        [qw/ my buy cancel /],
        { ( $args{id} ? +(id => $args{id}) : () ) }
    )
}


sub sendcoin {
    my $self = shift;
    my %args = @_;
    my %postdata;
    for my $k (qw/ cointype address amount /) {
        $postdata{$k} = $args{$k}
            if $args{$k};
    }
    return $self->_post(
        [qw/ my coin send /],
        \%postdata,
    )
}


sub depositcoin {
    my $self = shift;
    my %args = @_;
    return $self->_post(
        [qw/ my coin deposit /],
        { ( $args{cointype} ? +(cointype => $args{cointype}) : () ) }
    )
}


sub quotesell {
    my $self = shift;
    my %args = @_;
    my %postdata;
    for my $k (qw/ cointype amount /) {
        $postdata{$k} = $args{$k}
            if $args{$k};
    }
    return $self->_post(
        [qw/ quote sell /],
        \%postdata,
    )
}


sub sell {
    my $self = shift;
    my %args = @_;
    my %postdata;
    for my $k (qw/ cointype amount rate /) {
        $postdata{$k} = $args{$k}
            if $args{$k};
    }
    return $self->_post(
        [qw/ my sell /],
        \%postdata,
    )
}


sub cancelsell {
    my $self = shift;
    my %args = @_;
    return $self->_post(
        [qw/ my sell cancel /],
        { ( $args{id} ? +(id => $args{id}) : () ) }
    )
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::CoinSpot - Trade BitCoin, Ethereum, Monero and other CryptoCurrency via CoinSpot

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use WebService::CoinSpot;

 my $coinspot = WebService::CoinSpot->new(
     auth_key    => 'xxxxxxxx',
     auth_secret => 'xxxxxxxx',
     base_url    => 'https://www.coinspot.com.au', # optional, default shown

 );

=head1 DESCRIPTION

Trade BitCoin, Ethereum, Monero and other CryptoCurrency via the L<CoinSpot|https://www.coinspot.com.au?affiliate=6XUL8> vaguely RESTful API.

You will of course need to create an account on L<CoinSpot|https://www.coinspot.com.au?affiliate=6XUL8>, which is an Australian place to Trade CryptoCurrency.

=for Pod::Coverage BUILD

=head1 ALPHA STATUS WARNING

This API software is an Alpha release, which I am published for people to comment on and provide pull requests.

Test it carefully before relying upon it with your valuable currency.

=head1 METHODS

=head2 CoinSpot Object

=head3 new

 my $coinspot = WebService::CoinSpot->new(
     auth_key    => 'xxxxxxxx',
     auth_secret => 'xxxxxxxx',
     base_url    => 'https://www.coinspot.com.au', # optional, default shown
 );

Creates new object. No ping type operation is performed, so you won't know if there's is a problem with your parameters until you try to do something.

B<Parameters>

=over 4

=item auth_key

Optional. But without it you will only get some L</Market Status> features.

The API key that CoinSpot will provide you. Look on the account settings web page.

=item auth_secret

Optional. But without it you will only get some L</Market Status> features.

The Secret key that CoinSpot will provide you. Look on the account settings web page.

B<WARNING:> do not commit this secret to public source control repositories.

=item base_url

Optional.

Specify a different base URL for the API. This will likely never be needed.

=back

=head3 auth_key

Read only accessory for auth_key

=head3 auth_secret

Read only accessory for auth_secret

=head2 Market Status

Get information about whats happening in the market. None of these spend your money or sell your assets.

=head3 latest

 my $response = $coinspot->latest();

Get Latest Prices (doesn't require auth_key or auth_secret)

B<Parameters>

None.

B<Returns>

Hash or hash reference with all the latest prices.

=over 4

=item prices

One property for each coin with the latest prices for that coin

=back

=head3 orders

 my $response = $coinspot->orders( cointype => 'BTC' );

List Open Orders

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=back

B<Returns>

Hash or hash reference with all the latest open orders.

=over 4

=item buyorders

Array containing all the open buy orders

=item sellorders

Array containing all the open sell orders

=back

=head3 orders_history

 my $response = $coinspot->orders_history( cointype => 'BTC' );

List Order History

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=back

B<Returns>

Hash or hash reference with last 1,000 completed orders

=over 4

=item orders

Array of the last 1,000 completed orders

=back

=head2 My Account

Examine what's in your account. None of these functions spend your money or sell your assets.

=head3 balances

 my $response = $coinspot->balances();

List My Balances

B<Parameters>

None.

B<Returns>

Hash or hash reference with balances for your account

=over 4

=item balances

One property for each coin with your balance for that coin

=back

=head3 myorders

 my $response = $coinspot->myorders();

List My Orders

B<Parameters>

None.

B<Returns>

Hash or hash reference with balances for your account

=over 4

=item buyorders

Array containing all your buy orders

=item sellorders

Array containing all your sell orders

=back

=head2 Buying

Exchange AUD for CryptoCurrency. B<These functions will spend your money>.

=head3 quotebuy

 my $response = $coinspot->quotebuy(
     cointype => 'BTC',
     amount   => 9_999_999,
 );

Quick Buy Quote

B<Note:> This is just a quote, not a commitment to buy.

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=item amount

The amount of coins to buy

=back

B<Returns>

Hash or hash reference with estimations

=over 4

=item quote

The rate per coin

=item timeframe

Estimated hours to wait for trade to complete (0 = immediate trade)

=back

=head3 buy

 my $response = $coinspot->buy(
     cointype => 'BTC',
     amount   => 9_999_999,
     rate     => 0.50,
 );

Place Buy Order

B<DANGER DANGER DANGER>

This function will try to spend your hard earned money on CryptoCurrency.

B<DANGER DANGER DANGER>

You can cancel orders via L</cancelbuy>

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=item amount

The amount of coins to buy, max precision 8 decimal places

=item rate

The rate in AUD you are willing to pay, max precision 6 decimal places

=back

B<Returns>

Ok or error only.

=head3 cancelbuy

 my $response = $coinspot->cancelbuy( id => 1234 );

Cancel Buy Order

B<WARNING WARNING WARNING>

This function will cancel buy orders, if unfulfilled.

B<WARNING WARNING WARNING>

B<Parameters>

=over 4

=item id

The id of the order to cancel

=back

B<Returns>

Ok or error only.

=head2 Sending / Depositing

Moves / sends coins from wallet to wallet. B<These functions will cause assets to leave your CoinSpot account>.

=head3 sendcoin

 my $response = $coinspot->sendcoin(
     cointype => 'BTC',
     address  => 'abc1234',
     amount   => 9_999_999,
 );

Send Coins

B<DANGER DANGER DANGER>

This function will move assets from your CoinSpot account to other wallets.

B<DANGER DANGER DANGER>

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=item address

The address to send coins to

=item amount

The amount of coins to send

=back

B<Returns>

Ok or error only.

=head3 depositcoin

 my $response = $coinspot->depositcoin(
     cointype => 'BTC',
 );

Deposit Coins

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=back

B<Returns>

Hash or hash reference with estimations

=over 4

=item address

Your deposit address for the coin

=back

=head2 Selling

Exchange CryptoCurrency for AUD. B<These functions will sell your assets>

=head3 quotesell

 my $response = $coinspot->quotesell(
     cointype => 'BTC',
     amount   => 9_999_999,
 );

Quick Sell Quote

B<Note:> This is just a quote, not a commitment to sell.

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=item amount

The amount of coins to sell

=back

B<Returns>

Hash or hash reference with estimations

=over 4

=item quote

The rate per coin

=item timeframe

Estimated hours to wait for trade to complete (0 = immediate trade)

=back

=head3 sell

 my $response = $coinspot->sell(
     cointype => 'BTC',
     amount   => 9_999_999,
     rate     => 0.50,
 );

Place Sell Order

B<DANGER DANGER DANGER>

This function will try to sell your CryptoCurrency in exchange for Australian Dollars

B<DANGER DANGER DANGER>

You can cancel orders via L</cancelsell>

B<Parameters>

=over 4

=item cointype

i.e. BTC, LTC, DOGE, ETH, ETC.

=item amount

The amount of coins you want to sell, max precision 8 decimal places

=item rate

The rate in AUD you are willing to pay, max precision 6 decimal places

=back

B<Returns>

Ok or error only.

=head3 cancelsell

 my $response = $coinspot->cancelsell( id => 1234 );

Cancel Buy Order

B<WARNING WARNING WARNING>

This function will cancel sell orders, if unfulfilled.

B<WARNING WARNING WARNING>

B<Parameters>

=over 4

=item id

The id of the order to cancel

=back

B<Returns>

Ok or error only.

=head1 SEE ALSO

L<CoinSpot|https://www.coinspot.com.au?affiliate=6XUL8>

=head1 AUTHOR

Dean Hamstead <djzort@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
