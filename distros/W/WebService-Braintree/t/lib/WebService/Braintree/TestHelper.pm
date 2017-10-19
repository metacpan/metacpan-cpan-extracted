# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::TestHelper;

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use Data::Dumper;
use DateTime::Format::Strptime;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use MIME::Base64;
use Time::HiRes qw(gettimeofday);
use Try::Tiny;
use WebService::Braintree::Util qw(hash_to_query_string);
use DateTime::Format::Strptime;
use URI::Escape;

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
    not_ok
    perform_search
    should_throw
    should_throw_containing
    simulate_form_post_for_tr
    NON_DEFAULT_MERCHANT_ACCOUNT_ID
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
    my %required_plans = (
        integration_trialless_plan => superhashof(bless {
            price => '12.34',
            number_of_billing_cycles => undef,
            billing_day_of_month => undef,
            trial_period => 0,
            add_ons => [],
            discounts => [],
        }, 'WebService::Braintree::Plan'),
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
                }, 'Hash::Inflator'),
            ],
            discounts => [
                superhashof(bless {
                    id => 'discount_15',
                    amount => '15.00',
                    never_expires => 1,
                }, 'Hash::Inflator'),
            ],
        }, 'WebService::Braintree::Plan'),
    );
    my %plans = map {
        $_->id => $_
    } @{WebService::Braintree::Plan->all};

    return unless cmp_deeply(\%plans, superhashof(\%required_plans));

    my %required_merchants = (
        sandbox_master_merchant_account => superhashof(bless {
            id => 'sandbox_master_merchant_account',
            status => 'active',
            default => 1,
            sub_merchant_account => 0,
        }, 'WebService::Braintree::MerchantAccount'),
    );
    my %merchants = map {
        $_->id => $_
    } @{WebService::Braintree::MerchantAccount->all};

    return unless cmp_deeply(\%merchants, superhashof(\%required_merchants));

    return 1;
}

use constant NON_DEFAULT_MERCHANT_ACCOUNT_ID => 'sandbox_credit_card_non_default';

use constant TRIALLESS_PLAN_ID => 'integration_trialless_plan';

use constant THREE_D_SECURE_MERCHANT => 'three_d_secure_merchant_account';

sub not_ok {
    my($predicate, $message) = @_;
    ok(!$predicate, $message);
}

sub should_throw {
    my($exception, $block, $message) = @_;
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

sub settle {
    my $transaction_id = shift;
    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->put("/transactions/${transaction_id}/settle");

    my $x = WebService::Braintree::Result->new(response => $response);
    die Dumper($x) unless $x->is_success;
    return $x;
}

sub settlement_decline {
    my $transaction_id = shift;
    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->put("/transactions/${transaction_id}/settlement_decline");

    my $x = WebService::Braintree::Result->new(response => $response);
    die Dumper($x) unless $x->is_success;
    return $x;
}

sub settlement_pending {
    my $transaction_id = shift;
    my $http = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $response = $http->put("/transactions/${transaction_id}/settlement_pending");

    my $x = WebService::Braintree::Result->new(response => $response);
    die Dumper($x) unless $x->is_success;
    return $x;
}

sub create_settled_transaction {
    my ($params) = shift;

    my $sale = WebService::Braintree::Transaction->sale($params);
    die Dumper($sale) unless $sale->is_success;

    my $submit = WebService::Braintree::Transaction->submit_for_settlement($sale->transaction->id);
    die Dumper($submit) unless $submit->is_success;

    return settle($sale->transaction->id);
}

sub create_escrowed_transaction {
    my $sale = WebService::Braintree::Transaction->sale({
        amount => '50.00',
        merchant_account_id => 'sandbox_sub_merchant_account',
        credit_card => {
            number => '5431111111111111',
            expiration_date => '05/12',
        },
        service_fee_amount => '10.00',
        options => {
            hold_in_escrow => 'true',
        }
    });
    my $http       = WebService::Braintree::HTTP->new(config => WebService::Braintree->configuration);
    my $settlement = $http->put('/transactions/' . $sale->transaction->id . '/settle');
    die Dumper($settlement) if $settlement->{api_error_response};

    my $escrow     = $http->put('/transactions/' . $sale->transaction->id . '/escrow');
    die Dumper($escrow) if $escrow->{api_error_response};

    return WebService::Braintree::Result->new(response => $escrow);
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

sub simulate_form_post_for_tr {
    my ($tr_string, $form_params) = @_;
    my $escaped_tr_string = uri_escape($tr_string);
    my $tr_data = {tr_data => $escaped_tr_string, %$form_params};

    my $request = HTTP::Request->new(
        POST => WebService::Braintree->configuration->base_merchant_url . '/transparent_redirect_requests',
    );

    $request->content_type('application/x-www-form-urlencoded');
    $request->content(hash_to_query_string($tr_data));

    my $agent = LWP::UserAgent->new;
    my $response = $agent->request($request);
    my @url_and_query = split(/\?/, $response->header('location'), 2);
    return $url_and_query[1];
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
    return $body->{'paypalAccounts'}->[0]->{'nonce'};
}

sub generate_decoded_client_token {
    my $params = shift;
    my $encoded_client_token = WebService::Braintree::ClientToken->generate($params);
    my $decoded_client_token = decode_base64($encoded_client_token);

    $decoded_client_token;
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

1;
__END__
