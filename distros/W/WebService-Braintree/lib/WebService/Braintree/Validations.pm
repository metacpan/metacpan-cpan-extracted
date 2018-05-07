# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Validations;

use 5.010_001;
use strictures 1;

use WebService::Braintree::Util qw(is_hashref);

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    verify_params
    address_signature
    client_token_signature_with_customer_id
    client_token_signature_without_customer_id
    credit_card_signature
    credit_card_verification_signature
    customer_signature
    transaction_signature
    clone_transaction_signature
    merchant_account_signature
    transaction_search_results_signature
);

# verify_params() ensures:
# * the keys of $params are a subset of the keys of white_list
# * if the value of a key in either is a hashref, then:
#     * both must be hashrefs
#     * verify_params() holds for the values
# Edge cases:
# * if $params->{$key} is a hashref, the white_list can also be _any_key_. This
#   disables checking for the keys of $params->{$key}.

# This does a "return 0" instead of a "return" so that the tests are easier to
# write. Also, this forces scalar context on the returned value.
sub verify_params {
    my ($params, $white_list) = @_;

    foreach my $key (keys %$params) {
        return 0 unless exists $white_list->{$key};

        if (is_hashref($white_list->{$key})) {
            return 0 unless is_hashref($params->{$key});
            return 0 unless verify_params($params->{$key}, $white_list->{$key});
        } elsif (is_hashref($params->{$key})) {
            return 0 if $white_list->{$key} ne '_any_key_';
        }
    }

    return 1;
}

sub search_results_signature {
    return {
        page_size => 1,
        ids => 1,
    };
}

sub transaction_search_results_signature {
    return {
        search_results => search_results_signature,
    };
}

sub address_signature {
    return {
        company => 1,
        country_code_alpha2 => 1,
        country_code_alpha3 => 1,
        country_code_numeric => 1,
        country_name => 1,
        extended_address => 1,
        first_name => 1,
        options => {
            update_existing => 1,
        },
        last_name => 1,
        locality => 1,
        postal_code => 1,
        region => 1,
        street_address => 1,
    };
}

sub client_token_signature_with_customer_id {
    return {
        %{client_token_signature_without_customer_id()},
        customer_id => 1,
        options => {
            make_default => 1,
            fail_on_duplicate_payment_method => 1,
            verify_card => 1,
        },
    };
}

sub client_token_signature_without_customer_id {
    return {
        proxy_merchant_id => 1,
        version => 1,
        merchant_account_id => 1,
    };
}

sub credit_card_signature {
    return {
        customer_id => 1,
        billing_address_id => 1,
        cardholder_name => 1,
        cvv => 1,
        expiration_date => 1,
        expiration_month => 1,
        expiration_year => 1,
        number => 1,
        token => 1,
        venmo_sdk_payment_method_code => 1,
        payment_method_nonce => 1,
        device_session_id => 1,
        device_data => 1,
        fraud_merchant_id => 1,
        options => {
            make_default => 1,
            verification_merchant_account_id => 1,
            verify_card => 1,
            update_existing_token => 1,
            fail_on_duplicate_payment_method => 1,
            venmo_sdk_session => 1,
        },
        billing_address => address_signature,
    };
}

sub customer_signature {
    return {
        company => 1,
        email => 1,
        fax => 1,
        first_name => 1,
        id => 1,
        last_name => 1,
        phone => 1,
        website => 1,
        device_data => 1,
        device_session_id => 1,
        fraud_merchant_id => 1,
        credit_card => credit_card_signature,
        payment_method_nonce => 1,
        custom_fields => '_any_key_'
    };
}

sub clone_transaction_signature {
    return {
        amount => 1,
        channel => 1,
        options => {
            submit_for_settlement => 1,
        },
    };
}

sub credit_card_verification_signature {
    return {
        options => {
            amount => 1,
            merchant_account_id => 1,
        },
        credit_card => {
            cardholder_name => 1,
            cvv => 1,
            expiration_date => 1,
            expiration_month => 1,
            expiration_year => 1,
            number => 1,
            billing_address => address_signature,
        },
    }
}

sub transaction_signature{
    return {
        amount => 1,
        customer_id => 1,
        merchant_account_id => 1,
        order_id => 1,
        channel => 1,
        payment_method_token => 1,
        payment_method_nonce => 1,
        device_session_id => 1,
        device_data => 1,
        fraud_merchant_id => 1,
        billing_address_id => 1,
        purchase_order_number => 1,
        recurring => 1,
        shipping_address_id => 1,
        type => 1,
        tax_amount => 1,
        tax_exempt => 1,
        credit_card => {
            token => 1,
            cardholder_name => 1,
            cvv => 1,
            expiration_date => 1,
            expiration_month => 1,
            expiration_year => 1,
            number => 1,
        },
        customer => {
            id => 1,
            company => 1,
            email => 1,
            fax => 1,
            first_name => 1,
            last_name => 1,
            phone => 1,
            website => 1,
        } ,
        billing => address_signature,
        shipping => address_signature,
        options => {
            store_in_vault => 1,
            store_in_vault_on_success => 1,
            submit_for_settlement => 1,
            add_billing_address_to_payment_method => 1,
            store_shipping_address_in_vault => 1,
            venmo_sdk_session => 1,
            hold_in_escrow => 1,
            payee_email => 1,
        },
        paypal_account => {
            payee_email => 1,
        },
        custom_fields => '_any_key_',
        descriptor => {
            name => 1,
            phone => 1,
            url => 1,
        },
        subscription_id => 1,
        venmo_sdk_payment_method_code => 1,
        service_fee_amount => 1,
        three_d_secure_token => 1,
        line_items => 1,
    };
}

1;
__END__
