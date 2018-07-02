# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::TestHelper;

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use Carp qw(confess);
use Data::Dumper;
use DDP;
use DateTime::Format::Strptime;
use JSON;
use MIME::Base64;
use Time::HiRes qw(gettimeofday);
use Try::Tiny;
use DateTime::Format::Strptime;

use WebService::Braintree;
use WebService::Braintree::ClientApiHTTP;
use WebService::Braintree::ClientToken;
use WebService::Braintree::Util;

use Test::Deep;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    create_escrowed_transaction
    create_settled_transaction
    generate_unique_integer
    make_subscription_past_due
    amount
    not_ok
    perform_search
    should_throw
    should_throw_containing
    validate_result invalidate_result
    nonce_for_new_payment_method
    credit_card cc_number cc_last4 cc_bin cc_masked
    settle
);
our @EXPORT_OK = qw(
);

{
    my $config;
    sub config {
        return $config;
    }

    sub import {
        my ($class, $env) = @_;
        $env ||= 'integration';
        $class->export_to_level(1, @EXPORT);

        $config = WebService::Braintree->configuration;
        $config->environment($env);
        if ($env eq 'sandbox') {
            my $conf_file = 'sandbox_config.json';
            die "Can not run sandbox tests without $conf_file in distribution root" unless -e $conf_file;
            my $sandbox = decode_json( do { local $/; open my($f), $conf_file; <$f>} );
            $config->public_key($sandbox->{public_key});
            $config->merchant_id($sandbox->{merchant_id});
            $config->private_key($sandbox->{private_key});
        }
    }
}

# The sandbox must have specific items in it with specific values.
sub verify_sandbox {
    subtest verify_sandbox => sub {
        my %required_addons = (
            increase_30 => superhashof(bless {
                id => 'increase_30',
                amount => '30.00',
                never_expires => 1,
            }, 'WebService::Braintree::_::AddOn'),
        );
        my %addons = map {
            $_->id => $_
        } @{WebService::Braintree::AddOn->all};
        return unless cmp_deeply(\%addons, superhashof(\%required_addons), 'Validate addons');

        my %required_discounts = (
            discount_15 => superhashof(bless {
                id => 'discount_15',
                amount => '15.00',
                never_expires => 1,
            }, 'WebService::Braintree::_::Discount'),
        );
        my %discounts = map {
            $_->id => $_
        } @{WebService::Braintree::Discount->all};
        return unless cmp_deeply(\%discounts, superhashof(\%required_discounts), 'Validate discounts');

        my %required_plans = (
            integration_trialless_plan => superhashof(bless {
                price => '12.34',
                number_of_billing_cycles => undef,
                billing_day_of_month => undef,
                trial_period => 0,
                add_ons => [],
                discounts => [],
            }, 'WebService::Braintree::_::Plan'),
            integration_plan_with_add_ons_and_discounts => superhashof(bless {
                price => '1.00',
                number_of_billing_cycles => undef,
                billing_day_of_month => undef,
                trial_period => 1,
                add_ons => [
                    superhashof(bless {
                        id => 'increase_30',
                        amount => '30.00',
                        never_expires => 1,
                    }, 'WebService::Braintree::_::AddOn'),
                ],
                discounts => [
                    superhashof(bless {
                        id => 'discount_15',
                        amount => '15.00',
                        never_expires => 1,
                    }, 'WebService::Braintree::_::Discount'),
                ],
            }, 'WebService::Braintree::_::Plan'),
        );
        my %plans = map {
            $_->id => $_
        } @{WebService::Braintree::Plan->all};

        return unless cmp_deeply(\%plans, superhashof(\%required_plans), 'Validate plans');

        my %required_merchants = (
            sandbox_master_merchant_account => superhashof(bless {
                id => 'sandbox_master_merchant_account',
                status => 'active',
                #default => 1,
                #sub_merchant_account => 0,
            }, 'WebService::Braintree::_::MerchantAccount'),
            sandbox_credit_card => superhashof(bless {
                id => 'sandbox_credit_card',
                status => 'active',
                #default => 0,
                #sub_merchant_account => 0,
            }, 'WebService::Braintree::_::MerchantAccount'),
            three_d_secure_merchant_account => superhashof(bless {
                id => 'three_d_secure_merchant_account',
                status => 'active',
                #default => 0,
                #sub_merchant_account => 0,
            }, 'WebService::Braintree::_::MerchantAccount'),
        );
        my %merchants;
        WebService::Braintree::MerchantAccount->all->each(sub {
            my $merchant = shift;
            $merchants{$merchant->id} = $merchant;
        });

        return unless cmp_deeply(\%merchants, superhashof(\%required_merchants), 'Validate merchants');

        # id -> [ compare, create ]
        my %required_submerchants = (
            sandbox_sub_merchant_account => [
                superhashof(bless {
                    id => 'sandbox_sub_merchant_account',
                    status => 'active',
                    #default => 0,
                    #sub_merchant_account => 1,
                }, 'WebService::Braintree::_::MerchantAccount'),
                {
                    id => 'sandbox_sub_merchant_account',
                    master_merchant_account_id => 'sandbox_master_merchant_account',
                    tos_accepted => 1,
                    individual => {
                        first_name => 'John',
                        last_name => 'Smith',
                        email => 'john@smith.com',
                        phone => '1235551212',
                        date_of_birth => '1970-01-01',
                        address => {
                            street_address => '123 Main St',
                            locality => 'Anytown',
                            region => 'NY',
                            postal_code => '12345',
                        },
                    },
                    funding => {
                        descriptor => 'funding_destination',
                        destination => 'bank',
                        account_number => '123456789',
                        routing_number => '021000021', # Fake routing number
                    },
                },
            ],
        );

        while (my ($id, $details) = each %required_submerchants) {
            unless ($merchants{$id}) {
                my $result = WebService::Braintree::MerchantAccount->create(
                    $details->[1],
                );
                validate_result($result) or return;

                # Let the sub-merchant go active.
                sleep 10;

                # Refresh the list of merchants
                %merchants = ();
                WebService::Braintree::MerchantAccount->all->each(sub {
                    my $merchant = shift;
                    $merchants{$merchant->id} = $merchant;
                });
            }

            return unless cmp_deeply($merchants{$id}, $details->[0], "Validate sub-merchant '$id'");
        }
    };
}

use constant TRIALLESS_PLAN_ID => 'integration_trialless_plan';

use constant THREE_D_SECURE_MERCHANT => 'three_d_secure_merchant_account';

sub not_ok {
    my($predicate, $message) = @_;
    ok(!$predicate, $message);
}

sub should_throw {
    my($exception, $block, $message) = @_;
    $message //= '';
    try {
        $block->();
        fail($message . " [Should have thrown $exception]");
    } catch {
        like($_ , qr/^$exception.*/, $message);
    }
}

sub should_throw_containing {
    my($exception, $block, $message) = @_;
    try {
        $block->();
        fail($message . " [Should have thrown $exception]");
    } catch {
        like($_ , qr/.*$exception.*/, $message);
    }
}

sub validate_result {
    my ($result, $message) = @_;

    my $rv = ok($result->is_success, $message || 'Result okay');

    warn np($result) unless $rv;
    return $rv;
}

sub invalidate_result {
    my ($result, $message) = @_;

    my $rv = ok(!$result->is_success, $message || 'Result correct not okay');

    warn np($result) unless $rv;
    return $rv;
}

sub settle {
    my $transaction_id = shift;
    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->put("/transactions/${transaction_id}/settle");

    my $x = WebService::Braintree::Result->new({
        response => $response,
        %$response,
    });
    die Dumper($x) unless $x->is_success;
    return $x;
}

sub settlement_decline {
    my $transaction_id = shift;
    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->put("/transactions/${transaction_id}/settlement_decline");

    my $x = WebService::Braintree::Result->new({
        response => $response,
        %$response,
    });
    die Dumper($x) unless $x->is_success;
    return $x;
}

sub settlement_pending {
    my $transaction_id = shift;
    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->put("/transactions/${transaction_id}/settlement_pending");

    my $x = WebService::Braintree::Result->new({
        response => $response,
        %$response,
    });
    die Dumper($x) unless $x->is_success;
    return $x;
}

sub create_settled_transaction {
    my ($params) = shift;

    $params->{amount} //= amount(40, 60);

    my $sale = WebService::Braintree::Transaction->sale($params);
    die Dumper($sale) unless $sale->is_success;

    my $submit = WebService::Braintree::Transaction->submit_for_settlement($sale->transaction->id);
    die Dumper($submit) unless $submit->is_success;

    return settle($sale->transaction->id);
}

sub create_escrowed_transaction {
    my $sale = WebService::Braintree::Transaction->sale({
        amount => amount(40, 60),
        merchant_account_id => 'sandbox_sub_merchant_account',
        credit_card => credit_card(),
        service_fee_amount => amount(5, 15),
        options => {
            hold_in_escrow => 'true',
        }
    });
    my $http       = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $settlement = $http->put('/transactions/' . $sale->transaction->id . '/settle');
    die Dumper($settlement) if $settlement->{api_error_response};

    my $escrow     = $http->put('/transactions/' . $sale->transaction->id . '/escrow');
    die Dumper($escrow) if $escrow->{api_error_response};

    return WebService::Braintree::Result->new({
        response => $escrow,
        %$escrow,
    });
}

sub create_3ds_verification {
    my ($merchant_account_id, $params) = @_;

    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->post("/three_d_secure/create_verification/$merchant_account_id", {
        three_d_secure_verification => $params,
    });

    die Dumper($response) if $response->{api_error_response};

    return $response->{three_d_secure_verification}->{three_d_secure_token};
}

sub make_subscription_past_due {
    my $subscription_id = shift;

    my $request = WebService::Braintree->configuration->gateway->http->put(
        "/subscriptions/${subscription_id}/make_past_due?days_past_due=1",
    );
}

sub now_in_eastern {
    return DateTime->now(time_zone => 'America/New_York')->strftime('%Y-%m-%d');
}

sub parse_datetime {
    my $date_string = shift;
    my $parser = DateTime::Format::Strptime->new(
        pattern => '%F %T',
    );
    my $dt = $parser->parse_datetime($date_string);
}

sub get_new_http_client {
    my $config = __PACKAGE__->config;
    my $customer = WebService::Braintree::Customer->create()->customer;
    my $raw_client_token = WebService::Braintree::TestHelper::generate_decoded_client_token();
    my $client_token = decode_json($raw_client_token);

    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};
    return WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => 'fake_identifier',
        shared_customer_identifier_type => 'testing',
    );
}

sub get_nonce_for_new_card {
    my ($credit_card_number, $customer_id) = @_;

    my $raw_client_token = '';
    if ($customer_id eq '') {
        $raw_client_token = generate_decoded_client_token();
    } else {
        $raw_client_token = generate_decoded_client_token({customer_id => $customer_id});
    }
    my $client_token = decode_json($raw_client_token);
    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};

    my $config = __PACKAGE__->config;

    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => 'fake_identifier',
        shared_customer_identifier_type => 'testing',
    );

    return $http->get_nonce_for_new_card($credit_card_number, $customer_id);
}

sub generate_unlocked_nonce {
    my ($credit_card_number, $customer_id) = @_;
    my $raw_client_token = '';
    if (!defined($customer_id) || $customer_id eq '') {
        $raw_client_token = generate_decoded_client_token();
    } else {
        $raw_client_token = generate_decoded_client_token({customer_id => $customer_id});
    }

    my $client_token = decode_json($raw_client_token);

    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};
    my $config = __PACKAGE__->config;
    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => 'test-identifier',
        shared_customer_identifier_type => 'testing',
    );

    return $http->get_nonce_for_new_card('4111111111111111');
}

sub generate_one_time_paypal_nonce {
    my $customer_id = shift;
    my $raw_client_token = '';
    if (!defined($customer_id) || $customer_id eq '') {
        $raw_client_token = generate_decoded_client_token();
    } else {
        $raw_client_token = generate_decoded_client_token({customer_id => $customer_id});
    }

    my $client_token = decode_json($raw_client_token);

    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};
    my $config = __PACKAGE__->config;
    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => 'test-identifier',
        shared_customer_identifier_type => 'testing',
    );

    return $http->get_one_time_nonce_for_paypal();
}

sub generate_future_payment_paypal_nonce {
    my $customer_id = shift;
    my $raw_client_token = '';
    if (!defined($customer_id) || $customer_id eq '') {
        $raw_client_token = generate_decoded_client_token();
    } else {
        $raw_client_token = generate_decoded_client_token({customer_id => $customer_id});
    }

    my $client_token = decode_json($raw_client_token);

    my $authorization_fingerprint = $client_token->{'authorizationFingerprint'};
    my $config = __PACKAGE__->config;
    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $authorization_fingerprint,
        shared_customer_identifier => 'test-identifier',
        shared_customer_identifier_type => 'testing',
    );

    return $http->get_future_payment_nonce_for_paypal();
}

sub _nonce_from_response {
    my $response = shift;
    my $body = decode_json($response->content);

    if (defined($body->{'paypalAccounts'})) {
        return $body->{'paypalAccounts'}->[0]->{'nonce'};
    } else {
        return $body->{'creditCards'}->[0]->{'nonce'};
    }
}

sub nonce_for_new_payment_method {
    my $params = shift;
    my $raw_client_token = generate_decoded_client_token();
    my $client_token = decode_json($raw_client_token);
    my $config = __PACKAGE__->config;
    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $client_token->{'authorizationFingerprint'},
        shared_customer_identifier => 'fake_identifier',
        shared_customer_identifier_type => 'testing',
    );

    my $response = $http->add_payment_method($params);
    return _nonce_from_response($response);
}

sub nonce_for_new_credit_card {
    my $params = shift;
    my $http = get_new_http_client();
    return $http->get_nonce_for_new_card_with_params($params);
}

sub nonce_for_paypal_account {
    my $paypal_account_details = shift;
    my $raw_client_token = generate_decoded_client_token();
    my $client_token = decode_json($raw_client_token);
    my $config = __PACKAGE__->config;
    my $http = WebService::Braintree::ClientApiHTTP->new(
        config => $config,
        fingerprint => $client_token->{'authorizationFingerprint'}
    );

    my $response = $http->create_paypal_account($paypal_account_details);
    my $body = decode_json($response->content);
    my $nonce = $body->{'paypalAccounts'}->[0]->{'nonce'};
    confess("Cannot create Paypal Nonce:\n" . np($body)) unless $nonce;
    return $nonce;
}

sub generate_decoded_client_token {
    my $params = shift;
    my $encoded_client_token = WebService::Braintree::ClientToken->generate($params);
    return decode_base64($encoded_client_token);
}

sub generate_unique_integer {
    return int(gettimeofday * 1000);
}

sub perform_search {
    my ($class, $criteria) = @_;

    # XXX Why don't I use return here?
    "WebService::Braintree::${class}"->search(sub {
        my $search = shift;

        while (my($key, $value) = each(%$criteria)) {
            $search->$key->is($value);
        }

        return $search;
    });
}

# Add in the test amounts from https://developers.braintreepayments.com/reference/general/testing/ruby
sub amount {
    my ($min, $max) = @_;
    $min //= 10;
    $max //= 100;

    return (int(rand(100*($max - $min))) + 100*$min)/100;
}

sub credit_card {
    my ($params) = @_;
    $params //= {};
    return {
        number => cc_number('mastercard'),
        expiration_date => '05/12',
        %$params,
    };
}

# This list is taken from
# https://developers.braintreepayments.com/reference/general/testing/ruby
my %cc_numbers = (
    amex => [
        '378282246310005',
        '371449635398431',
    ],
    diners_club => [
        '36259600000004',
    ],
    discover => [
        '6011111111111117'
    ],
    jcb => [
        '3530111333300000',
    ],
    maestro => [
        '6304000000000000',
    ],
    mastercard => [
        '5431111111111111',
        '5555555555554444',
        '2223000048400011',
    ],
    visa => [
        '4111111111111111',
        '4005519200000004',
        '4009348888881881',
        '4012000033330026',
        '4012000077777777',
        '4012888888881881',
        '4217651111111119',
        '4500600000000061',
    ],
    fraud => [
        '4000111111111511',
    ],
    fails_verification => [
        # processor_declined
        '4000111111111115', # visa
        '5105105105105100', # mastercard
        #'378734493671000',  # amex < Do not use this because the CVV error trumps all
        '6011000990139424', # discover
        '38520000009814',   # diners_club
        # failed (3000)
        #'3566002020360505', # jcb
    ],
    dispute => [
        '4023898493988028', # creates a settled sale with an open dispute
    ],
);
sub cc_number {
    my ($type) = @_;

    my @choices = $type
        ? @{$cc_numbers{$type}}
        : (map { @{$cc_numbers{$_}} } qw(mastercard visa));
    return $choices[rand @choices];
}

sub cc_last4 {
    my ($number) = @_;
    return substr($number, -4);
}

sub cc_bin {
    my ($number) = @_;
    return substr($number, 0, 6);
}

sub cc_masked {
    my ($number) = @_;

    return cc_bin($number)
        . '*' x (length($number) - 10)
        . cc_last4($number);
}

1;
__END__
