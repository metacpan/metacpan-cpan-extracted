#!/usr/bin/perl

use strict;
use warnings;

use HTTP::Response;
use Test::More;
use Test::Fatal;
use Module::Spy;

use WebService::OANDA::ExchangeRates;

like(
    exception{ WebService::OANDA::ExchangeRates->new() },
    qr{^Missing required arguments: api_key},
    'dies when missing api_key in constructor'
);

my $api = WebService::OANDA::ExchangeRates->new(api_key => 'AN_API_KEY');
my $raw_data = '{"success": "1"}';

# test read only methods
foreach my $ro_method (qw{base_url proxy timeout api_key user_agent}) {
    like(
        exception { $api->$ro_method('a new value') },
        qr{$ro_method},
        "$ro_method is read only"
    );
}

# replace get() with a spy to prevent an actual call to the API
my $spy = spy_on( $api->user_agent, 'get' )->and_returns(
    HTTP::Response->new( 200, 'Ok', undef, $raw_data )
);

# test invalid arguments to get_rates
my @failures = (
    { args => {}, like => qr{missing required parameter}, msg => 'no args' },
    {   args => { base_currency => 'usd' },
        msg  => 'incorrectly formatted base_currency'
    },
    {   args => { base_currency => 'USD', not_a_real_field => 1 },
        like => qr{^invalid parameter},
        msg  => 'invalid parameter'
    },
    {   args => { base_currency => 'USD', quote => 'xxx' },
        msg => 'incorrectly formatted quote currency',
    },
    {   args => { base_currency => 'USD', quote => [qw{ xxx EUR }] },
        msg => 'incorrectly formatted quote currency list',
    },
    {   args => { base_currency => 'USD', date => '20141512' },
        msg  => 'incorrectly formatted date',
    },
    {   args => { base_currency => 'USD', start => '20141512' },
        msg => 'incorrectly formatted start date',
    },
    {   args => { base_currency => 'USD', end => '20141512' },
        msg => 'incorrectly formatted end date',
    },
    {   args =>
            { base_currency => 'USD', decimal_places => 'something else' },
        msg => 'incorrectly formatted decimal_places',
    },
);

foreach my $scenario (@failures) {
    my $like_regex = exists $scenario->{like}
                   ? $scenario->{like}
                   : qr{^invalid value};
    like(
        exception { $api->get_rates( %{$scenario->{args}}) },
        $like_regex,
        'correctly failed with ' . $scenario->{msg}
    );
}

done_testing();
