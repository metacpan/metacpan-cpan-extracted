# NAME

WebService::Cryptsy - implementation of www.cryptsy.com API

# SYNOPSIS

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

# MAINTENANCE NOTE

**NOTE: this module has not been keeping up with Cryptsy's API updates
since Feb 4, 2014. Reason being is that I don't personally use this
module and the person I wrote it for might not be using it any more
either. But if you do use this module and need it updated, just
submit a bug report (patches are also welcome!).**

# DESCRIPTION

This module implements the [www.cryptsy.com API](https://www.cryptsy.com/pages/api) whose description is available here:
[https://www.cryptsy.com/pages/api](https://www.cryptsy.com/pages/api)

# INSTALLATION NOTES

Depending on your configuration, you might need to install

    cpan LWP::Protocol::https  Net::SSLeay

Or some such, to make [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) work over HTTPS, as that's what
Cryptsy's API requires.

# GETTING API KEY

To use this module, you'll need to obtain the API key from
[www.cryptsy.com](https://www.cryptsy.com/). Once logged in,
go to [account settings page](https://www.cryptsy.com/users/settings)
and scroll all the way to the bottom. Click the _Generate New Key_ button
to generate new key.

**IMPORTANT!!! Ensure to toggle the "API Disabled"
button into the "on" position, otherwise your API will be off and this
module will give a confusing error message.**

# CONSTRUCTOR

## `new`

    my $cryp = WebService::Cryptsy->new(
        public_key  => 'YOUR PUBLIC  KEY',
        private_key => 'YOUR PRIVATE KEY',
        timeout     => 30,
    );

    # or if you're only going to use the public methods:
    my $cryp = WebService::Cryptsy->new;

Creates and returns a new `WebService::Cryptsy` object. **Takes**
three optional arguments as key/value pairs. The
`public_key` and `private_key` are optional only for the
_Public Methods_ of the API. They both are required for calling the
_Authenticated Methods_. To obtain your keys, see the ["GETTING API KEY"](#getting-api-key)
section above.

### `public_key`

    my $cryp = WebService::Cryptsy->new(
        public_key  => '479c5eee116f8f5972bdaf12dd0a3f82562c8a7c',
        private_key => 'b408e899526142eee13304669a657c8782435ccda2f65dbea05270fe8dfa5d3d2ef7eb4812ce1c35',
    );

This is the key from the _Public Key_ box on
[Cryptsy's settings page](https://www.cryptsy.com/users/settings).

### `private_key`

    my $cryp = WebService::Cryptsy->new(
        public_key  => '479c5eee116f8f5972bdaf12dd0a3f82562c8a7c',
        private_key => 'b408e899526142eee13304669a657c8782435ccda2f65dbea05270fe8dfa5d3d2ef7eb4812ce1c35',
    );

This is the key from the _Private Key_ box on
[Cryptsy's settings page](https://www.cryptsy.com/users/settings).

### `timeout`

    my $cryp = WebService::Cryptsy->new(
        timeout => 30,
    );

**Optional**. Specifies the timeout, in seconds, of the API requests.
**Default:** `60`

# MODULE METHODS / OVERLOADS

## `error`

    # these two are equivalent
    my $data = $cryp->marketdata
        or die "Error: $cryp";


    my $data = $cryp->marketdata
        or die "Error: " . $cryp->error;

The API methods will return `undef` or an empty list,
depending on the context, and the human-readable error will be available
using the `->error` method. This method is overloaded for object
interpolation, thus you can simply interpolate the object in a string
to get the error message.

## `timeout`

    printf "Current API request timeout is %d\n", $cryp->timeout;

    $cryp->timeout( 30 );

Gets/sets the `timeout` constructor's argument. **Takes** one optional
argument that specifies the new timeout in seconds. **Returns** the
current timeout in seconds.

# GENERAL CONVENTION FOR API METHODS

All methods are named exactly the same as in
[Cryptsy's API](https://www.cryptsy.com/pages/api). If the API method
takes any arguments, you'd supply them to the method, in the same order
(e.g. `$cryp->mytrades( $market_id,  $limit );`)

# PUBLIC API METHODS

These methods do not require API keys.

## `marketdata`

    my $data = $cryp->marketdata
        or die "Error: $cryp";

**NOTE: this API call doesn't seem to be listed on Cryptsy's site
any more. You're likely supposed to use marketdatav2 instead.**

**NOTE: sometimes this call takes forever to complete.**

_General Market Data (All Markets): (OLD METHOD)_. **Takes** no arguments. **On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

## `marketdatav2`

    my $data = $cryp->marketdatav2
        or die "Error: $cryp";

**NOTE: sometimes this call takes forever to complete.**

_General Market Data (All Markets): (NEW METHOD)_. **Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

## `singlemarketdata`

    my $market_id = 60; #  IFC/LTC market
    my $data = $cryp->singlemarketdata( $market_id )
        or die "Error: $cryp";

_General Market Data (Single Market)_.
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

## `orderdata`

    my $data = $cryp->orderdata
        or die "Error: $cryp";

_General Orderbook Data (All Markets)_.
**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

## `singleorderdata`

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->singleorderdata( $market_id )
        or die "Error: $cryp";

_General Orderbook Data (Single Market)_.
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

# AUTHENTICATED API METHODS

## `getinfo`

    my $data = $cryp->getinfo
        or die "Error: $cryp";

**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

And according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of these keys is:

- `balances_available`  Array of currencies and the balances
available for each
- `balances_hold`   Array of currencies and the amounts currently on
hold for open orders
- `servertimestamp` Current server timestamp
- `servertimezone`  Current timezone for the server
- `serverdatetime`  Current date/time on the server
- `openordercount`  Count of open orders on your account

## `getmarkets`

    my $data = $cryp->getmarkets
        or die "Error: $cryp";

_Outputs: Array of Active Markets_.
**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

And according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of these keys is:

- `marketid` Integer value representing a market
- `label`   Name for this market, for example: `AMC/BTC`
- `primary_currency_code`   Primary currency code,
for example: `AMC`
- `primary_currency_name`   Primary currency name, for example:
`AmericanCoin`
- `secondary_currency_code` Secondary currency code, for example:
`BTC`
- `secondary_currency_name` Secondary currency name, for example:
`BitCoin`
- `current_volume` 24 hour trading volume in this market
- `last_trade` Last trade price for this market
- `high_trade` 24 hour highest trade price in this market
- `low_trade` 24 hour lowest trade price in this market
- `created` Datetime (EST) the market was created

## `mytransactions`

    my $data = $cryp->mytransactions
        or die "Error: $cryp";

_Outputs: Array of Deposits and Withdrawals on your account_.
**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
**On success** returns a data structure.
**Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.**
My best guess is it returns an arrayref of hashrefs, and
according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `currency` Name of currency account
- `timestamp` The timestamp the activity posted
- `datetime` The datetime the activity posted
- `timezone` Server timezone
- `type` Type of activity. (Deposit / Withdrawal)
- `address` Address to which the deposit posted
or Withdrawal was sent
- `amount` Amount of transaction (Not including any fees)
- `fee` Fee (If any) Charged for this Transaction
(Generally only on Withdrawals)
- `trxid`   Network Transaction ID (If available)

## `markettrades`

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->markettrades( $market_id )
        or die "Error: $cryp";

_Outputs: Array of last 1000 Trades for this Market,
in Date Descending Order_.
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

And according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `tradeid` A unique ID for the trade
- `datetime`    Server datetime trade occurred
- `tradeprice`  The price the trade occurred at
- `quantity`    Quantity traded
- `total`   Total value of trade (tradeprice \* quantity)
- `initiate_ordertype`  The type of order which initiated this trade

## `marketorders`

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->marketorders( $market_id )
        or die "Error: $cryp";

_Outputs: 2 Arrays. First array is sellorders
listing current open sell orders ordered price ascending. Second array is buyorders listing current open buy orders ordered price descending._
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

And according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `sellprice` If a sell order, price which order is selling at
- `buyprice` If a buy order, price the order is buying at
- `quantity` Quantity on order
- `total` Total value of order (price \* quantity)

## `mytrades`

    my $market_id = 68; #  CSC/BTC market
    my $limit = 200;
    my $data = $cryp->mytrades( $market_id, $limit )
        or die "Error: $cryp";

_Outputs: Array your Trades for this Market, in Date Descending Order._
**Takes** one **mandatory** argument, which is the market ID, and
one **optional** argument, which is the limit of the number of results
(**defaults to** `200`).
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
On success returns a data structure.
**Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.**
My best guess is it returns an arrayref of hashrefs, and
according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `tradeid` An integer identifier for this trade
- `tradetype`   Type of trade (Buy/Sell)
- `datetime`    Server datetime trade occurred
- `tradeprice`  The price the trade occurred at
- `quantity`    Quantity traded
- `total`   Total value of trade (tradeprice \* quantity)-
Does not include fees
- `fee` Fee Charged for this Trade
- `initiate_ordertype`  The type of order which initiated this trade
- `order_id`    Original order id this trade was executed against

## `allmytrades`

    my $data = $cryp->allmytrades
        or die "Error: $cryp";

_Outputs: Array your Trades for all Markets, in Date Descending Order_.
**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
**On success** returns a data structure.
**Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.**
My best guess is it returns an arrayref of hashrefs, and
according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `tradeid`   An integer identifier for this trade
- `tradetype`   Type of trade (Buy/Sell)
- `datetime`    Server datetime trade occurred
- `marketid`    The market in which the trade occurred
- `tradeprice`  The price the trade occurred at
- `quantity`    Quantity traded
- `total`   Total value of trade (tradeprice \* quantity) -
Does not include fees
- `fee` Fee Charged for this Trade
- `initiate_ordertype`  The type of order which initiated this trade
- `order_id`    Original order id this trade was executed against

## `myorders`

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->myorders( $market_id )
        or die "Error: $cryp";

_Outputs: Array of your orders for this market
listing your current open sell and buy orders._
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
**On success** returns a data structure.
**Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.**
My best guess is it returns an arrayref of hashrefs, and
according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `orderid` Order ID for this order
- `created` Datetime the order was created
- `ordertype`   Type of order (Buy/Sell)
- `price`   The price per unit for this order
- `quantity`    Quantity remaining for this order
- `total`   Total value of order (price \* quantity)
- `orig_quantity`   Original Total Order Quantity

## `depth`

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->depth( $market_id )
        or die "Error: $cryp";

_Outputs: Array of buy and sell orders on the market
representing market depth._
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
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

## `allmyorders`

    my $data = $cryp->allmyorders
        or die "Error: $cryp";

_Outputs: Array of all open orders for your account._
**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
**On success** returns a data structure.
**Since I don't actually use Cryptsy, I've no transactions and can't
see what structure the method returns. If you can, please dump it and
submit it as a bug report.**
My best guess is it returns an arrayref of hashrefs, and
according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in each hashref is:

- `orderid` Order ID for this order
- `marketid` The Market ID this order was created for
- `created` Datetime the order was created
- `ordertype` Type of order (Buy/Sell)
- `price` The price per unit for this order
- `quantity` Quantity remaining for this order
- `total` Total value of order (price \* quantity)
- `orig_quantity` Original Total Order Quantity

## `createorder`

    my $order_id = $cryp->createorder(
        $marketid,   # Market ID for which you are creating an order for
        $ordertype,  # Order type you are creating (Buy/Sell)
        $quantity,   # Amount of units you are buying/selling in this order
        $price,      # Price per unit you are buying/selling at
    ) or die "Error: $cryp";

**Takes** four mandatory arguments that are (in order):
market id, order type (Buy or Sell), quantity, price.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
**On success** returns the order ID.

## `cancelorder`

    $cryp->cancelorder( $order_id )
        or die "Error: $cryp";

**Takes** one **mandatory** argument, which is the order ID of the order
you wish to cancel.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
**On success** returns a true value.

## `cancelmarketorders`

    my $market_id = 68; #  CSC/BTC market
    my $data = $cryp->cancelmarketorders( $market_id )
        or die "Error: $cryp";

_Cancel all open orders in the market._
**Takes** one **mandatory** argument, which is the market ID.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
According to the API docs, on success returns an arrayref that
contains _"return information on each order cancelled."_
**I don't have the means to create/cancel orders; if you can dump
the returned data structure and submit it to me via a bug report,
it would be appreciated.** It is likely the return is a hashref with
a single key `return` whose value is an arrayref.

## `cancelallorders`

    my $data = $cryp->cancelallorders
        or die "Error: $cryp";

_Outputs: Array of all open orders for your account._
**Takes** no arguments.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
According to the API docs, on success returns an arrayref that
contains _"return information on each order cancelled."_
**I don't have the means to create/cancel orders; if you can dump
the returned data structure and submit it to me via a bug report,
it would be appreciated.** It is likely the return is a hashref with
a single key `return` whose value is an arrayref.

## `calculatefees`

    my $data = $cryp->calculatefees(
        $ordertype,  # Order type you are calculating for (Buy/Sell)
        $quantity,   # Amount of units you are buying/selling
        $price,      # Price per unit you are buying/selling at
    ) or die "Error: $cryp";

**Takes** three mandatory arguments that are (in order):
order type (Buy or Sell), quantity, price.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
On success returns a data structure that looks like this:

    {
        'fee' => '11.94000000',
        'net' => '3968.06000000'
    }

And according to [Cryptsy's API](https://www.cryptsy.com/pages/api),
the meaning of the keys in the hashref is:

- `fee` The that would be charged for provided inputs
- `net` The net total with fees

## `generatenewaddress`

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

**Takes** two optional arguments, but at least one of them must be provided.
The first argument is the currency ID, the second is the currency code.
If you're providing the currency code but wish not to provide the
currency ID, then provide currency ID as `undef`.
**On failure** returns `undef` or an empty list,
depending on the context, and sets `->error` to the error message.
On success returns a data structure that looks something like this:

    {
        'address' => '16zJ1sR9RBEsWsAzy8uZYM2Lr65691kwqD'
    };

# REPOSITORY

Fork this module on GitHub:
[https://github.com/zoffixznet/WebService-Cryptsy](https://github.com/zoffixznet/WebService-Cryptsy)

# BUGS

To report bugs or request features, please use
[https://github.com/zoffixznet/WebService-Cryptsy/issues](https://github.com/zoffixznet/WebService-Cryptsy/issues)

If you can't access GitHub, you can email your request
to `bug-WebService-Cryptsy at rt.cpan.org`

# AUTHOR

Zoffix Znet <zoffix at cpan.org>
([http://zoffix.com/](http://zoffix.com/), [http://haslayout.net/](http://haslayout.net/))

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
