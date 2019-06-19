use strict;
use warnings;

use JSON::MaybeXS qw( JSON );
use Test::Fatal qw( exception );
use Test::More 0.88;
use WebService::MinFraud::Validator ();

my $validator = WebService::MinFraud::Validator->new;

subtest 'minium chargeback request' => sub {
    my $good_request = { ip_address => '24.24.24.24' };
    ok(
        $validator->validate_request( $good_request, 'chargeback' ),
        'good request validates'
    );
};

subtest 'good chargeback request with optional fields' => sub {
    my $good_request = {
        ip_address      => '24.24.24.24',
        chargeback_code => 'Test Chargeback Code',
        tag             => 'spam_or_abuse',
        maxmind_id      => 'a' x 8,
        minfraud_id     => 'b' x 36,
        transaction_id  => 'Test-transaction-id'
    };
    ok(
        $validator->validate_request( $good_request, 'chargeback' ),
        'good request with optional fields validates'
    );
};

subtest 'bad chargeback tag' => sub {
    my $bad_request = {
        ip_address => '24.24.24.24',
        tag        => 'suspended_account'
    };
    like(
        exception {
            $validator->validate_request( $bad_request, 'chargeback' );
        },
        qr/matched none of the available alternative/,
        'bad tag type throws an exception'
    );
};

subtest 'bad chargeback maxmind_id' => sub {
    my $bad_request = {
        ip_address => '24.24.24.24',
        maxmind_id => 'b' x 9
    };
    like(
        exception {
            $validator->validate_request( $bad_request, 'chargeback' );
        },
        qr/length of value is outside allowed range/,
        'bad maxmind_id throws an exception'
    );
};

subtest 'bad chargeback minfraud_id' => sub {
    my $bad_request = {
        ip_address  => '24.24.24.24',
        minfraud_id => 'a' x 37
    };
    like(
        exception {
            $validator->validate_request( $bad_request, 'chargeback' );
        },
        qr/length of value is outside allowed range/,
        'bad minfraud_id throws an exception'
    );
};

subtest 'empty chargeback request' => sub {
    my $empty_request = {};
    like(
        exception {
            $validator->validate_request( $empty_request, 'chargeback' );
        },
        qr/no value given for required entry/,
        'empty request throws an exception'
    );
};

subtest 'minimum request' => sub {
    my $good_request = { device => { ip_address => '24.24.24.24' } };
    ok(
        $validator->validate_request($good_request),
        'good request validates'
    );
};

subtest 'empty request' => sub {
    my $empty_request = {};
    like(
        exception { $validator->validate_request($empty_request); },
        qr/no value given for required entry device/,
        'empty request throws an exception'
    );
};

subtest 'request with session values' => sub {
    my $good_request = {
        device => {
            ip_address  => '24.24.24.24',
            session_age => 3600.8,
            session_id  => 'foobar',
        }
    };
    ok(
        $validator->validate_request($good_request),
        'good request validates'
    );
};

subtest 'username_md' => sub {
    my $good_username = {
        device  => { ip_address   => '24.24.24.24' },
        account => { username_md5 => 'A' x 32 }
    };
    ok(
        $validator->validate_request($good_username),
        'good username validates'
    );
    my $bad_username_md5 = {
        device  => { ip_address   => '24.24.24.24' },
        account => { username_md5 => 'A' x 33 },
    };
    like(
        exception { $validator->validate_request($bad_username_md5); },
        qr/not a 32 digit hexadecimal/,
        'bad username_md5 throws an exception'
    );
};

subtest 'last_4_digits' => sub {
    my $good_last_4_digits = {
        device      => { ip_address    => '24.24.24.24' },
        credit_card => { last_4_digits => '1' x 4 },
    };
    ok(
        $validator->validate_request($good_last_4_digits),
        'good last 4 digits validates'
    );
    my $bad_last_4_digits = {
        device      => { ip_address    => '24.24.24.24' },
        credit_card => { last_4_digits => '1' x 3 },
    };
    like(
        exception { $validator->validate_request($bad_last_4_digits); },
        qr/length of value is outside allowed range/,
        'bad last 4 digits throws an exception'
    );
};

subtest 'avs_result' => sub {
    my $good_avs_result = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { avs_result => 'Y' },
    };
    ok(
        $validator->validate_request($good_avs_result),
        'good avs result validates'
    );
    my $bad_avs_result = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { avs_result => 'YY' },
    };
    like(
        exception { $validator->validate_request($bad_avs_result); },
        qr/length of value is outside allowed range/,
        'bad avs_result throws an exception'
    );
};

subtest 'cvv_result' => sub {
    my $good_cvv_result = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { cvv_result => 'N', avs_result => 'Y' },
    };
    ok(
        $validator->validate_request($good_cvv_result),
        'good cvv result validates'
    );
    my $bad_cvv_result = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { cvv_result => q{} },
    };
    like(
        exception { $validator->validate_request($bad_cvv_result); },
        qr/length of value is outside allowed range/,
        'bad cvv_result throws an exception'
    );
};

subtest 'cc_token' => sub {
    my $good_cc_token = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { token      => 'a' x 20 },
    };
    ok(
        $validator->validate_request($good_cc_token),
        'good cvv result validates'
    );
    my $bad_cc_token = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { token      => 'a' x 256 },
    };
    like(
        exception { $validator->validate_request($bad_cc_token); },
        qr{Failed /maxmind/cctoken},
        'a cc token greater 255 characters throws an exception'
    );
    $bad_cc_token = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { token      => 1 x 19 },
    };
    like(
        exception { $validator->validate_request($bad_cc_token); },
        qr{Failed /maxmind/cctoken},
        'a cc token of all numbers less than 20 digits in length throws an exception'
    );
    $bad_cc_token = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { token      => q( ) },
    };
    like(
        exception { $validator->validate_request($bad_cc_token); },
        qr{Failed /maxmind/cctoken},
        'a space in the cc token throws an exception'
    );
    $bad_cc_token = {
        device      => { ip_address => '24.24.24.24' },
        credit_card => { token      => "\x7F" },
    };
    like(
        exception { $validator->validate_request($bad_cc_token); },
        qr{Failed /maxmind/cctoken},
        'a delete in the cc token throws an exception'
    );
};

subtest 'Domain validation' => sub {
    my %base              = ( device => { ip_address => '24.24.24.24' } );
    my $good_email_domain = {
        %base,
        email => { domain => 'zed.com' },
    };

    ok(
        $validator->validate_request($good_email_domain),
        'good email domain validates'
    );

    my $fake_tld_email_domain = {
        %base,
        email => { domain => 'zed.faketld' },
    };

    ok(
        $validator->validate_request($fake_tld_email_domain),
        'TLD is not validated'
    );

    my $bad_email_domain = {
        %base,
        email => { domain => '-X-.com' },
    };
    like(
        exception { $validator->validate_request($bad_email_domain); },
        qr/not a valid host name/,
        'bad email domain throws an exception'
    );
};

subtest 'event time' => sub {
    my $good_event_time = {
        device => { ip_address => '24.24.24.24' },
        event  => { time       => '2015-10-10T12:00:00Z' },
    };
    ok(
        $validator->validate_request($good_event_time),
        'good event time validates'
    );
    my $bad_event_time = {
        device => { ip_address => '24.24.24.24' },
        event  => { time       => '2015-10-10 12:00:00' },
    };
    like(
        exception { $validator->validate_request($bad_event_time); },
        qr/ not a RFC3339/,
        'bad event time throws an exception'
    );
};

subtest 'event type' => sub {
    my @good = (
        {
            device => { ip_address => '24.24.24.24' },
            event =>
                { type => 'purchase', time => '2015-10-10T12:00:00-07:00' },
        },
        {
            device => { ip_address => '24.24.24.24' },
            event  => { type       => 'password_reset' },
        },
        {
            device => { ip_address => '24.24.24.24' },
            event  => { type       => 'email_change' },
        },
        {
            device => { ip_address => '24.24.24.24' },
            event  => { type       => 'payout_change' },
        },
    );
    for my $good_event_type (@good) {
        ok(
            $validator->validate_request($good_event_type),
            'good event type validates'
        );
    }

    my $bad_event_type = {
        device => { ip_address => '24.24.24.24' },
        event  => { type       => 'estudi' },
    };
    like(
        exception { $validator->validate_request($bad_event_type); },
        qr/matched none of the available alternative/,
        'bad event type throws an exception'
    );
};

subtest 'order currency' => sub {
    my $good_order_currency = {
        device => { ip_address => '24.24.24.24' },
        order  => { currency   => 'EUR' },
    };
    ok(
        $validator->validate_request($good_order_currency),
        'good order currency validates'
    );
    my $bad_order_currency = {
        device => { ip_address => '24.24.24.24' },
        order  => { currency   => '2015-10-10 12:00:00' },
    };
    like(
        exception { $validator->validate_request($bad_order_currency); },
        qr/length of value is outside allowed range/,
        'bad order currency throws an exception'
    );
};

subtest 'referrer' => sub {
    my $good_referrer = {
        device => { ip_address   => '24.24.24.24' },
        order  => { referrer_uri => 'http://whutsup.org' },
    };
    ok(
        $validator->validate_request($good_referrer),
        'good order referrer validates'
    );
    my $bad_referrer = {
        device => { ip_address   => '24.24.24.24' },
        order  => { referrer_uri => 'httpz://whutsup.metge' },
    };
    like(
        exception { $validator->validate_request($bad_referrer); },
        qr/Found value is not a valid Web URI/,
        'bad order referrer throws an exception'
    );
};

subtest 'payment processor' => sub {
    my $good_payment_processor = {
        device  => { ip_address => '24.24.24.24' },
        payment => { processor  => 'redpagos' },
    };
    ok(
        $validator->validate_request($good_payment_processor),
        'good payment processor validates'
    );
    my $bad_payment_processor = {
        device  => { ip_address => '24.24.24.24' },
        payment => { processor  => '2015-10-10 12:00:00' },
    };
    like(
        exception { $validator->validate_request($bad_payment_processor); },
        qr/matched none of the available alternative/,
        'bad payment processor throws an exception'
    );
};

subtest 'delivery speed' => sub {
    my $good_delivery_speed = {
        device   => { ip_address     => '24.24.24.24' },
        shipping => { delivery_speed => 'same_day' },
    };
    ok(
        $validator->validate_request($good_delivery_speed),
        'good delivery speed validates'
    );
    my $bad_delivery_speed = {
        device   => { ip_address     => '24.24.24.24' },
        shipping => { delivery_speed => 'two_day' },
    };
    like(
        exception { $validator->validate_request($bad_delivery_speed); },
        qr/matched none of the available alternatives/,
        'bad delivery speed throws an exception'
    );
};

subtest 'shipping country' => sub {
    my $good_shipping_country = {
        device   => { ip_address => '24.24.24.24' },
        shipping => { country    => 'AD' },
    };
    ok(
        $validator->validate_request($good_shipping_country),
        'good shipping country validates'
    );
    my $bad_shipping_country = {
        device   => { ip_address => '24.24.24.24' },
        shipping => { country    => 'USA' },
    };
    like(
        exception { $validator->validate_request($bad_shipping_country); },
        qr/length of value is outside allowed range/,
        'bad shipping country throws an exception'
    );
};

subtest 'billing country' => sub {
    my $bad_billing_country = {
        device  => { ip_address => '24.24.24.24' },
        billing => { country    => q{} },
    };
    like(
        exception { $validator->validate_request($bad_billing_country); },
        qr/length of value is outside allowed range/,
        'empty string as a billing country throws an exception'
    );
    ok(
        $validator->validate_request(
            $validator->_delete($bad_billing_country)
        ),
        'delete removes an undefined value'
    );
};

subtest 'booleans' => sub {
    my $false_boolean = {
        device  => { ip_address => '24.24.24.24' },
        payment => {
            decline_code   => 'invalid number',
            was_authorized => JSON()->false,
            processor      => 'stripe'
        },
    };
    ok(
        $validator->validate_request($false_boolean),
        'zero as a boolean validates'
    );
    my $true_boolean = {
        device  => { ip_address => '24.24.24.24' },
        payment => {
            decline_code   => 'invalid number',
            was_authorized => JSON()->true,
            processor      => 'stripe'
        },
    };
    ok(
        $validator->validate_request($true_boolean),
        'one as a boolean validates'
    );
    my $undef_boolean = {
        device  => { ip_address => '24.24.24.24' },
        payment => {
            decline_code   => 'invalid number',
            was_authorized => undef,
            processor      => 'stripe'
        },
    };

    like(
        exception { $validator->validate_request($undef_boolean) },
        qr/found value was not a bool/,
        'undef as a boolean does not validate'
    );
};

subtest 'custom inputs' => sub {
    ok(
        $validator->validate_request(
            {
                device        => { ip_address => '24.24.24.24' },
                custom_inputs => {
                    float_input   => 12.1,
                    integer_input => 3123,
                    string_input  => 'This is a string input.',
                    boolean_input => JSON()->true,
                },
            },
        ),
        'custom input types validate correctly'
    );

    for my $bad_inputs (
        [ 'invalid key',             { InvalidKey  => 1 } ],
        [ 'string that is too long', { too_long    => 'x' x 256 } ],
        [ 'string with newline',     { has_newline => "test\n" } ],
        [ 'arrayref custom inputs', [] ],
    ) {
        like(
            exception {
                !$validator->validate_request(
                    {
                        device        => { ip_address => '24.24.24.24' },
                        custom_inputs => $bad_inputs->[1],
                    },
                )
            },
            qr/Found invalid/,
            "$bad_inputs->[0] is invalid"
        );
    }
};

subtest 'session age' => sub {
    my $bad_session_age = {
        device => { ip_address => '24.24.24.24', session_age => 'foo', },
    };
    like(
        exception { $validator->validate_request($bad_session_age); },
        qr/not a number/,
        'bad session_age throws an exception'
    );
};

subtest 'session id' => sub {
    my %id_exceptions = (
        'undef' => { id => undef, expect => qr{found value is undef}, },
        'empty string' => { id => q{}, expect => qr{outside allowed range}, },
        'long id' =>
            { id => 'x' x 266, expect => qr{outside allowed range}, },
    );

    for my $name ( keys %id_exceptions ) {
        my $test = $id_exceptions{$name};

        my $request = {
            device =>
                { ip_address => '24.24.24.24', session_id => $test->{id}, },
        };
        like(
            exception { $validator->validate_request($request); },
            $test->{expect},
            $name . ' throws an exception'
        );
    }
};

done_testing;
