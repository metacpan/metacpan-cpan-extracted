package WebService::Cryptsy;

use Moo;

our $VERSION = '1.008007'; # VERSION

use URI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Digest::SHA qw/hmac_sha512_hex/;
use HTTP::Request::Common qw/POST/;

use constant API_POST_URL => 'https://api.cryptsy.com/api';
use constant API_GET_URL  => 'http://pubapi.cryptsy.com/api.php';
use overload '""' => sub { shift->error };


has public_key  => ( is => 'ro', );
has private_key => ( is => 'ro', );
has error       => ( is => 'rw', );
has timeout     => ( is => 'rw', default => 60 );

########## API METHODS ##########
sub marketdata      { return shift->_api_query('marketdata'     ); }
sub marketdatav2    { return shift->_api_query('marketdatav2'   ); }
sub orderdata       { return shift->_api_query('orderdata'      ); }
sub getinfo         { return shift->_api_query('getinfo'        ); }
sub getmarkets      { return shift->_api_query('getmarkets'     ); }
sub mytransactions  { return shift->_api_query('mytransactions' ); }
sub allmyorders     { return shift->_api_query('allmyorders'    ); }
sub cancelallorders { return shift->_api_query('cancelallorders'); }
sub allmytrades     { return shift->_api_query('allmytrades'    ); }

sub singlemarketdata {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'singlemarketdata', marketid => $market_id,
    );
}

sub singleorderdata {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'singleorderdata', marketid => $market_id,
    );
}

sub markettrades {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'markettrades', marketid => $market_id,
    );
}

sub marketorders {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'marketorders', marketid => $market_id,
    );
}

sub mytrades {
    my ( $self, $market_id, $limit ) = @_;
    $limit ||= 200;
    return $self->_api_query(
        'mytrades', marketid => $market_id, limit => $limit,
    );
}

sub myorders {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'myorders', marketid => $market_id,
    );
}

sub depth {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'depth', marketid => $market_id,
    );
}

sub createorder {
    my ( $self, $market_id, $order_type, $quantity, $price ) = @_;
    return $self->_api_query(
        'createorder',
        marketid    => $market_id,
        ordertype   => $order_type,
        quantity    => $quantity,
        price       => $price,
    );
}

sub cancelorder {
    my ( $self, $order_id ) = @_;
    return $self->_api_query(
        'cancelorder', orderid => $order_id,
    );
}

sub cancelmarketorders {
    my ( $self, $market_id ) = @_;
    return $self->_api_query(
        'cancelmarketorders', marketid => $market_id,
    );
}

sub calculatefees {
    my ( $self, $order_type, $quantity, $price ) = @_;
    return $self->_api_query(
        'calculatefees',
        ordertype   => $order_type,
        quantity    => $quantity,
        price       => $price,
    );
}

sub generatenewaddress {
    my ( $self, $currency_id, $currency_code ) = @_;
    return $self->_api_query(
        'generatenewaddress',
     ( defined $currency_id   ? ( currencyid => $currency_id     ) : () ),
     ( defined $currency_code ? ( currencycode => $currency_code ) : () ),
    );
}


########## MODULE METHODS ##########
sub _decode {
    my ( $self, $json, $method ) = @_;

    unless ( $json ) {
        $self->error('Network error: got no data');
        return
    }

    $self->error( undef );

    my $decoded = eval { decode_json( $json ); };
    if ( $@ ) {
        $self->error('JSON parsing error: ' . $@);
        return;
    }

    unless ( $decoded and $decoded->{success} ) {
        $self->error( $decoded && $decoded->{error}
            ? $decoded->{error}
            : 'Unknown JSON parsing error'
        );
        return;
    }

    ## Seems to be a bug in API, as it returns a null instead of an
    ## Empty array, as it does for other similar methods
    $decoded->{return} = []
        if not defined $decoded->{return}
            and (
                   $method eq 'mytransactions'
                or $method eq 'cancelmarketorders'
                or $method eq 'cancelallorders'
            );

    if ( $method eq 'cancelorder' ) {
        $decoded->{return} = 1;
    }

    unless ( $decoded->{return} ) {
        $self->error('Return given by Cryptsy is empty');
        return;
    }

    return $decoded->{return};
}

sub _api_query {
    my ( $self, $method, %req_args ) = @_;


    my $ua = LWP::UserAgent->new( timeout => $self->timeout );
    my $res;
    my %get_methods = map +( $_ => 1 ), qw/
        marketdata  marketdatav2     singlemarketdata
        orderdata   singleorderdata
    /;
    if ( $get_methods{ $method } ) {
        my $url = URI->new( API_GET_URL );
        $url->query_form(
            method  => $method,
            $method =~ /^single(market|order)data$/
            ? ( marketid => $req_args{marketid} ) : ()
        );

        $res = $ua->get( $url );
    }
    else {
        my $req = POST(
            API_POST_URL, [
                %req_args,
                method => $method,
                nonce  => time(),
            ]
        );

        my $digest = hmac_sha512_hex( $req->content, $self->private_key );
        $req->header( Sign => $digest,           );
        $req->header( Key  => $self->public_key, );

        $res = $ua->request( $req );
    }

    unless ( $res->is_success ) {
        $self->error('Network error: ' . $res->status_line );
        return;
    }
    return $self->_decode( $res->decoded_content, $method );
}


1;

__END__

=encoding utf8

=for stopwords EST Orderbook buyorders com cryptsy sellorders tradeprice www www.cryptsy.com www.cryptsy.com. marketdatav marketdatav2

=head1 NAME

WebService::Cryptsy - implementation of www.cryptsy.com API

=head1 SYNOPSIS

    use WebService::Cryptsy;
    use Data::Dumper;

    my $cryp = WebService::Cryptsy->new(
        public_key  => 'YOUR PUBLICE KEY',
        private_key => 'YOUR PRIVATE KEY',
    );

    print Dumper( $cryp->getinfo      || $cryp->error ) . "\n";
    print Dumper( $cryp->marketdatav2 || $cryp->error ) . "\n";

    my ( $currency_id, $currency_code ) = ( 3, 'BTC' );
    my $generated_address
    = $cryp->generatenewaddress( $currency_id, $currency_code )
        or die "Error: " . $cryp->error;


    $cryp = WebService::Cryptsy->new; # no need for keys for some methods
    my $data = $cryp->marketdatav2
        or die "Error: $cryp";  # error checking and using interpolation
                                # to get the error message

    printf "%s: %f\n", @{ $data->{markets}{$_} }{qw/label  lasttradeprice/}
        for sort keys %{ $data->{markets} };

=head1 MAINTENANCE NOTE

B<NOTE: this module has not been keeping up with Cryptsy's API updates
since Feb 4, 2014. Reason being is that I don't personally use this
module and the person I wrote it for might not be using it any more
either. But if you do use this module and need it updated, just
submit a bug report (patches are also welcome!).>

=head1 DESCRIPTION

This module implements the L<www.cryptsy.com API|https://www.cryptsy.com/pages/api> whose description is available here:
L<https://www.cryptsy.com/pages/api|https://www.cryptsy.com/pages/api>

=head1 INSTALLATION NOTES

Depending on your configuration, you might need to install

    cpan LWP::Protocol::https  Net::SSLeay

Or some such, to make L<LWP::UserAgent> work over HTTPS, as that's what
Cryptsy's API requires.

=head1 GETTING API KEY

To use this module, you'll need to obtain the API key from
L<www.cryptsy.com|https://www.cryptsy.com/>. Once logged in,
go to L<account settings page|https://www.cryptsy.com/users/settings>
and scroll all the way to the bottom. Click the I<Generate New Key> button
to generate new key.

B<IMPORTANT!!! Ensure to toggle the "API Disabled"
button into the "on" position, otherwise your API will be off and this
module will give a confusing error message.>

=head1 CONSTRUCTOR

=head2 C<new>

    my $cryp = WebService::Cryptsy->new(
        public_key  => 'YOUR PUBLIC  KEY',
        private_key => 'YOUR PRIVATE KEY',
        timeout     => 30,
    );

    # or if you're only going to use the public methods:
    my $cryp = WebService::Cryptsy->new;

Creates and returns a new C<WebService::Cryptsy> object. B<Takes>
three optional arguments as key/value pairs. The
C<public_key> and C<private_key> are optional only for the
I<Public Methods> of the API. They both are required for calling the
I<Authenticated Methods>. To obtain your keys, see the L<GETTING API KEY>
section above.

=head3 C<public_key>

    my $cryp = WebService::Cryptsy->new(
        public_key  => '479c5eee116f8f5972bdaf12dd0a3f82562c8a7c',
        private_key => 'b408e899526142eee13304669a657c8782435ccda2f65dbea05270fe8dfa5d3d2ef7eb4812ce1c35',
    );

This is the key from the I<Public Key> box on
L<Cryptsy's settings page|https://www.cryptsy.com/users/settings>.

=head3 C<private_key>

    my $cryp = WebService::Cryptsy->new(
        public_key  => '479c5eee116f8f5972bdaf12dd0a3f82562c8a7c',
        private_key => 'b408e899526142eee13304669a657c8782435ccda2f65dbea05270fe8dfa5d3d2ef7eb4812ce1c35',
    );

This is the key from the I<Private Key> box on
L<Cryptsy's settings page|https://www.cryptsy.com/users/settings>.

=head3 C<timeout>

    my $cryp = WebService::Cryptsy->new(
        timeout => 30,
    );

B<Optional>. Specifies the timeout, in seconds, of the API requests.
B<Default:> C<60>

=head1 MODULE METHODS / OVERLOADS

=head2 C<error>

    # these two are equivalent
    my $data = $cryp->marketdata
        or die "Error: $cryp";


    my $data = $cryp->marketdata
        or die "Error: " . $cryp->error;

The API methods will return C<undef> or an empty list,
depending on the context, and the human-readable error will be available
using the C<< ->error >> method. This method is overloaded for object
interpolation, thus you can simply interpolate the object in a string
to get the error message.

=head2 C<timeout>

    printf "Current API request timeout is %d\n", $cryp->timeout;

    $cryp->timeout( 30 );

Gets/sets the C<timeout> constructor's argument. B<Takes> one optional
argument that specifies the new timeout in seconds. B<Returns> the
current timeout in seconds.

=head1 GENERAL CONVENTION FOR API METHODS

All methods are named exactly the same as in
L<Cryptsy's API|https://www.cryptsy.com/pages/api>. If the API method
takes any arguments, you'd supply them to the method, in the same order
(e.g. C<< $cryp->mytrades( $market_id,  $limit ); >>)

=head1 PUBLIC API METHODS

These methods do not require API keys.

=head2 C<marketdata>

    my $data = $cryp->marketdata
        or die "Error: $cryp";

B<NOTE: this API call doesn't seem to be listed on Cryptsy's site
any more. You're likely supposed to use marketdatav2 instead.>

B<NOTE: sometimes this call takes forever to complete.>

I<General Market Data (All Markets): (OLD METHOD)>. B<Takes> no arguments. B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'markets' => {
            'CSC' => {
                    'primaryname' => 'CasinoCoin',
                    'volume' => '192807.99239834',
                    'lasttradeprice' => '0.00006507',
                    'marketid' => '68',
                    'secondarycode' => 'BTC',
                    'primarycode' => 'CSC',
                    'lasttradetime' => '2013-12-26 01:16:24',
                    'label' => 'CSC/BTC',
                    'secondaryname' => 'BitCoin',
                    'buyorders' => [
                        {
                            'quantity' => '0.00000000',
                            'price' => '0.00007348',
                            'total' => '1.17579218'
                        },
                    ],
                    'sellorders' => [
                        {
                            'quantity' => '0.00000000',
                            'price' => '0.00005005',
                            'total' => '0.01253232'
                        },
                    ],
                    'recenttrades' => [
                        {
                          'time' => '2013-12-26 01:27:33',
                          'quantity' => '2.69061569',
                          'price' => '0.00007095',
                          'id' => '9622421',
                          'total' => '0.00019090'
                        },
                    ],
            },
        },
    };

=head2 C<marketdatav2>

    my $data = $cryp->marketdatav2
        or die "Error: $cryp";

B<NOTE: sometimes this call takes forever to complete.>

I<General Market Data (All Markets): (NEW METHOD)>. B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'markets' => {
            'IFC/LTC' => {
                'primaryname' => 'InfiniteCoin',
                'secondaryname' => 'LiteCoin',
                'label' => 'IFC/LTC',
                'volume' => '413934622.38106910',
                'lasttradeprice' => '0.00000289',
                'marketid' => '60',
                'primarycode' => 'IFC',
                'secondarycode' => 'LTC',
                'lasttradetime' => '2013-12-26 01:37:09',
                'sellorders' => [
                    {
                        'quantity' => '0.00000000',
                        'price' => '0.00000286',
                        'total' => '8.64783388'
                    },
                ],
                'buyorders' => [
                    {
                        'quantity' => '0.00000000',
                        'price' => '0.00000293',
                        'total' => '2.15336758',
                    },
                ],
                'recenttrades' => [
                    {
                        'time' => '2013-12-26 01:40:36',
                        'quantity' => '10000.00000000',
                        'price' => '0.00000292',
                        'id' => '9626105',
                        'total' => '0.02920000',
                    },
                ],
            },
        }
    };

=head2 C<singlemarketdata>

    my $market_id = 60; #  IFC/LTC market
    my $data = $cryp->singlemarketdata( $market_id )
        or die "Error: $cryp";

I<General Market Data (Single Market)>.
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'markets' => {
            'IFC' => {
                'primaryname' => 'InfiniteCoin',
                'volume' => '405825211.07019660',
                'lasttradeprice' => '0.00000292',
                'marketid' => '60',
                'secondarycode' => 'LTC',
                'primarycode' => 'IFC',
                'lasttradetime' => '2013-12-26 01:45:50',
                'label' => 'IFC/LTC',
                'secondaryname' => 'LiteCoin',
                'buyorders' => [
                    {
                       'quantity' => '0.00000000',
                       'price' => '0.00000293',
                       'total' => '2.15336758'
                    },
                ],
                'sellorders' => [
                    {
                        'quantity' => '0.00000000',
                        'price' => '0.00000286',
                        'total' => '8.64783388'
                    },
                ],
                'recenttrades' => [
                    {
                        'time' => '2013-12-26 01:45:50',
                        'quantity' => '100000.00000000',
                        'price' => '0.00000292',
                        'id' => '9627226',
                        'total' => '0.29200000'
                    },
                ]
            }
        }
    };

=head2 C<orderdata>

    my $data = $cryp->orderdata
        or die "Error: $cryp";

I<General Orderbook Data (All Markets)>.
B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'CSC' => {
            'primaryname' => 'CasinoCoin',
            'secondaryname' => 'BitCoin',
            'marketid' => '68',
            'secondarycode' => 'BTC',
            'primarycode' => 'CSC',
            'label' => 'CSC/BTC',
            'sellorders' => [
                {
                    'quantity' => '0.00000000',
                    'price' => '0.00005005',
                    'total' => '0.01253232'
                },
            ],
            'buyorders' => [
                {
                    'quantity' => '0.00000000',
                    'price' => '0.00007348',
                    'total' => '1.17579218'
                },
            ],
        },
    };

=head2 C<singleorderdata>

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->singleorderdata( $market_id )
        or die "Error: $cryp";

I<General Orderbook Data (Single Market)>.
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'CSC' => {
            'primaryname' => 'CasinoCoin',
            'marketid' => '68',
            'secondarycode' => 'BTC',
            'primarycode' => 'CSC',
            'label' => 'CSC/BTC',
            'secondaryname' => 'BitCoin',
            'buyorders' => [
                {
                    'quantity' => '0.00000000',
                    'price' => '0.00007348',
                    'total' => '1.17579218'
                },
            ],
            'sellorders' => [
                {
                    'quantity' => '0.00000000',
                    'price' => '0.00005005',
                    'total' => '0.01253232'
                },
            ],
        }
    };

=head1 AUTHENTICATED API METHODS

=head2 C<getinfo>

    my $data = $cryp->getinfo
        or die "Error: $cryp";

B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'openordercount' => 0,
        'servertimestamp' => 1388083631,
        'servertimezone' => 'EST',
        'balances_available' => {
            'DBL' => '0.00000000',
            'CMC' => '0.00000000'
        },
        'serverdatetime' => '2013-12-26 13:47:11',
        'balances_hold' => {
            'CSC' => '0.00000000',
            'HYC' => '0.00000000',
        }
    };

And according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of these keys is:

=over 4

=item * C<balances_available>  Array of currencies and the balances
available for each

=item * C<balances_hold>   Array of currencies and the amounts currently on
hold for open orders

=item * C<servertimestamp> Current server timestamp

=item * C<servertimezone>  Current timezone for the server

=item * C<serverdatetime>  Current date/time on the server

=item * C<openordercount>  Count of open orders on your account

=back

=head2 C<getmarkets>

    my $data = $cryp->getmarkets
        or die "Error: $cryp";

I<Outputs: Array of Active Markets>.
B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    [
        {
            'current_volume' => '1147913.14033064',
            'marketid' => '57',
            'created' => '2013-07-04 01:01:09',
            'high_trade' => '0.00001638',
            'primary_currency_name' => 'AlphaCoin',
            'secondary_currency_name' => 'BitCoin',
            'last_trade' => '0.00001366',
            'primary_currency_code' => 'ALF',
            'label' => 'ALF/BTC',
            'secondary_currency_code' => 'BTC',
            'low_trade' => '0.00001067'
        },
    ];

And according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of these keys is:

=over 4

=item * C<marketid> Integer value representing a market

=item * C<label>   Name for this market, for example: C<AMC/BTC>

=item * C<primary_currency_code>   Primary currency code,
for example: C<AMC>

=item * C<primary_currency_name>   Primary currency name, for example:
C<AmericanCoin>

=item * C<secondary_currency_code> Secondary currency code, for example:
C<BTC>

=item * C<secondary_currency_name> Secondary currency name, for example:
C<BitCoin>

=item * C<current_volume> 24 hour trading volume in this market

=item * C<last_trade> Last trade price for this market

=item * C<high_trade> 24 hour highest trade price in this market

=item * C<low_trade> 24 hour lowest trade price in this market

=item * C<created> Datetime (EST) the market was created

=back

=head2 C<mytransactions>

    my $data = $cryp->mytransactions
        or die "Error: $cryp";

I<Outputs: Array of Deposits and Withdrawals on your account>.
B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
B<On success> returns a data structure.
B<Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.>
My best guess is it returns an arrayref of hashrefs, and
according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<currency> Name of currency account

=item * C<timestamp> The timestamp the activity posted

=item * C<datetime> The datetime the activity posted

=item * C<timezone> Server timezone

=item * C<type> Type of activity. (Deposit / Withdrawal)

=item * C<address> Address to which the deposit posted
or Withdrawal was sent

=item * C<amount> Amount of transaction (Not including any fees)

=item * C<fee> Fee (If any) Charged for this Transaction
(Generally only on Withdrawals)

=item * C<trxid>   Network Transaction ID (If available)

=back

=head2 C<markettrades>

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->markettrades( $market_id )
        or die "Error: $cryp";

I<Outputs: Array of last 1000 Trades for this Market,
in Date Descending Order>.
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    [
        {
            'quantity' => '73.90140550',
            'tradeid' => '9811863',
            'initiate_ordertype' => 'Sell',
            'total' => '0.00423825',
            'tradeprice' => '0.00005735',
            'datetime' => '2013-12-26 16:22:52'
        },
    ];

And according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<tradeid> A unique ID for the trade

=item * C<datetime>    Server datetime trade occurred

=item * C<tradeprice>  The price the trade occurred at

=item * C<quantity>    Quantity traded

=item * C<total>   Total value of trade (tradeprice * quantity)

=item * C<initiate_ordertype>  The type of order which initiated this trade

=back

=head2 C<marketorders>

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->marketorders( $market_id )
        or die "Error: $cryp";

I<Outputs: 2 Arrays. First array is sellorders
listing current open sell orders ordered price ascending. Second array is buyorders listing current open buy orders ordered price descending.>
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'sellorders' => [
            {
                'sellprice' => '0.00005740',
                'quantity' => '212.47116097',
                'total' => '0.01219584'
            },
        ],
        'buyorders' => [
            {
                'quantity' => '200.00000000',
                'buyprice' => '0.00005737',
                'total' => '0.01147400'
            },
        ],
    };

And according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<sellprice> If a sell order, price which order is selling at

=item * C<buyprice> If a buy order, price the order is buying at

=item * C<quantity> Quantity on order

=item * C<total> Total value of order (price * quantity)

=back

=head2 C<mytrades>

    my $market_id = 68; #  CSC/BTC market
    my $limit = 200;
    my $data = $cryp->mytrades( $market_id, $limit )
        or die "Error: $cryp";

I<Outputs: Array your Trades for this Market, in Date Descending Order.>
B<Takes> one B<mandatory> argument, which is the market ID, and
one B<optional> argument, which is the limit of the number of results
(B<defaults to> C<200>).
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure.
B<Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.>
My best guess is it returns an arrayref of hashrefs, and
according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<tradeid> An integer identifier for this trade

=item * C<tradetype>   Type of trade (Buy/Sell)

=item * C<datetime>    Server datetime trade occurred

=item * C<tradeprice>  The price the trade occurred at

=item * C<quantity>    Quantity traded

=item * C<total>   Total value of trade (tradeprice * quantity)-
Does not include fees

=item * C<fee> Fee Charged for this Trade

=item * C<initiate_ordertype>  The type of order which initiated this trade

=item * C<order_id>    Original order id this trade was executed against

=back

=head2 C<allmytrades>

    my $data = $cryp->allmytrades
        or die "Error: $cryp";

I<Outputs: Array your Trades for all Markets, in Date Descending Order>.
B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
B<On success> returns a data structure.
B<Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.>
My best guess is it returns an arrayref of hashrefs, and
according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<tradeid>   An integer identifier for this trade

=item * C<tradetype>   Type of trade (Buy/Sell)

=item * C<datetime>    Server datetime trade occurred

=item * C<marketid>    The market in which the trade occurred

=item * C<tradeprice>  The price the trade occurred at

=item * C<quantity>    Quantity traded

=item * C<total>   Total value of trade (tradeprice * quantity) -
Does not include fees

=item * C<fee> Fee Charged for this Trade

=item * C<initiate_ordertype>  The type of order which initiated this trade

=item * C<order_id>    Original order id this trade was executed against

=back

=head2 C<myorders>

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->myorders( $market_id )
        or die "Error: $cryp";

I<Outputs: Array of your orders for this market
listing your current open sell and buy orders.>
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
B<On success> returns a data structure.
B<Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.>
My best guess is it returns an arrayref of hashrefs, and
according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<orderid> Order ID for this order

=item * C<created> Datetime the order was created

=item * C<ordertype>   Type of order (Buy/Sell)

=item * C<price>   The price per unit for this order

=item * C<quantity>    Quantity remaining for this order

=item * C<total>   Total value of order (price * quantity)

=item * C<orig_quantity>   Original Total Order Quantity

=back

=head2 C<depth>

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->depth( $market_id )
        or die "Error: $cryp";

I<Outputs: Array of buy and sell orders on the market
representing market depth.>
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'buy' => [
            [
                '0.00005633', # price
                '2.70000000'  # quantity
            ],
        ],
        'sell' => [
            [
                '0.00005641', # price
                '73.44390000' # quantity
            ],
        ]
    };

=head2 C<allmyorders>

    my $data = $cryp->allmyorders
        or die "Error: $cryp";

I<Outputs: Array of all open orders for your account.>
B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
B<On success> returns a data structure.
B<Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.>
My best guess is it returns an arrayref of hashrefs, and
according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in each hashref is:

=over 4

=item * C<orderid> Order ID for this order

=item * C<marketid> The Market ID this order was created for

=item * C<created> Datetime the order was created

=item * C<ordertype> Type of order (Buy/Sell)

=item * C<price> The price per unit for this order

=item * C<quantity> Quantity remaining for this order

=item * C<total> Total value of order (price * quantity)

=item * C<orig_quantity> Original Total Order Quantity

=back

=head2 C<createorder>

    my $order_id = $cryp->createorder(
        $marketid,   # Market ID for which you are creating an order for
        $ordertype,  # Order type you are creating (Buy/Sell)
        $quantity,   # Amount of units you are buying/selling in this order
        $price,      # Price per unit you are buying/selling at
    ) or die "Error: $cryp";

B<Takes> four mandatory arguments that are (in order):
market id, order type (Buy or Sell), quantity, price.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
B<On success> returns the order ID.

=head2 C<cancelorder>

    $cryp->cancelorder( $order_id )
        or die "Error: $cryp";

B<Takes> one B<mandatory> argument, which is the order ID of the order
you wish to cancel.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
B<On success> returns a true value.

=head2 C<cancelmarketorders>

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->cancelmarketorders( $market_id )
        or die "Error: $cryp";

I<Cancel all open orders in the market.>
B<Takes> one B<mandatory> argument, which is the market ID.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
According to the API docs, on success returns an arrayref that
contains I<"return information on each order cancelled.">
B<I don't have the means to create/cancel orders; if you can dump
the returned data structure and submit it to me via a bug report,
it would be appreciated.> It is likely the return is a hashref with
a single key C<return> whose value is an arrayref.

=head2 C<cancelallorders>

    my $data = $cryp->cancelallorders
        or die "Error: $cryp";

I<Outputs: Array of all open orders for your account.>
B<Takes> no arguments.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
According to the API docs, on success returns an arrayref that
contains I<"return information on each order cancelled.">
B<I don't have the means to create/cancel orders; if you can dump
the returned data structure and submit it to me via a bug report,
it would be appreciated.> It is likely the return is a hashref with
a single key C<return> whose value is an arrayref.

=head2 C<calculatefees>

    my $data = $cryp->calculatefees(
        $ordertype,  # Order type you are calculating for (Buy/Sell)
        $quantity,   # Amount of units you are buying/selling
        $price,      # Price per unit you are buying/selling at
    ) or die "Error: $cryp";

B<Takes> three mandatory arguments that are (in order):
order type (Buy or Sell), quantity, price.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks like this:

    {
        'fee' => '11.94000000',
        'net' => '3968.06000000'
    }

And according to L<Cryptsy's API|https://www.cryptsy.com/pages/api>,
the meaning of the keys in the hashref is:

=over 4

=item * C<fee> The that would be charged for provided inputs

=item * C<net> The net total with fees

=back

=head2 C<generatenewaddress>

    my $address = $cryp->generatenewaddress(
        3,      # Currency ID for the coin you want to
                # generate a new address for (ie. 3 = BitCoin)
        'BTC',  # Currency Code for the coin you want to generate a new
                # address for (ie. BTC = BitCoin)
    ) or die "Error: $cryp";

    my $address = $cryp->generatenewaddress( 3 )
        or die "Error: $cryp";

    my $address = $cryp->generatenewaddress( undef, 'BTC' )
        or die "Error: $cryp";

B<Takes> two optional arguments, but at least one of them must be provided.
The first argument is the currency ID, the second is the currency code.
If you're providing the currency code but wish not to provide the
currency ID, then provide currency ID as C<undef>.
B<On failure> returns C<undef> or an empty list,
depending on the context, and sets C<< ->error >> to the error message.
On success returns a data structure that looks something like this:

    {
        'address' => '16zJ1sR9RBEsWsAzy8uZYM2Lr65691kwqD'
    };

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/WebService-Cryptsy>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/WebService-Cryptsy/issues>

If you can't access GitHub, you can email your request
to C<bug-WebService-Cryptsy at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut