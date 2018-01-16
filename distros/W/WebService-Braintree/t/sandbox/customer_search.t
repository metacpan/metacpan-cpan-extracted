# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper qw(sandbox);
use WebService::Braintree::Util;
use DateTime;
use DateTime::Duration;
use Storable qw(dclone);

{
    my $attrs = {
        first_name => "NotInFaker",
        last_name => "O'Toole",
        email => 'timmy@example.com',
        fax => "3145551234",
        phone => "5551231234",
        website => "http://example.com",
        credit_card => credit_card({
            cardholder_name => "NotIn Tool",
            billing_address => {
                first_name => "Thomas",
                last_name => "Otool",
                street_address => "1 E Main St",
                extended_address => "Suite 3",
                locality => "Chicago",
                region => "Illinois",
                postal_code => "60622",
                country_name => "United States of America",
            },
        }),
    };

    sub create_customer {
        my ($company, $token) = @_;

        my $this = dclone($attrs);
        $this->{company} = $company;
        $this->{credit_card}{token} = $token;

        return WebService::Braintree::Customer->create($this);
    }

    sub make_search_criteria {
        my ($company, $token) = @_;

        return {
            company => $company,
            payment_method_token => $token,
            first_name => $attrs->{first_name},
            last_name => $attrs->{last_name},
            email => $attrs->{email},
            phone => $attrs->{phone},
            fax => $attrs->{fax},
            website => $attrs->{website},
            address_first_name => $attrs->{credit_card}{billing_address}{first_name},
            address_last_name => $attrs->{credit_card}{billing_address}{last_name},
            address_street_address => $attrs->{credit_card}{billing_address}{street_address},
            address_postal_code => $attrs->{credit_card}{billing_address}{postal_code},
            address_extended_address => $attrs->{credit_card}{billing_address}{extended_address},
            address_locality => $attrs->{credit_card}{billing_address}{locality},
            address_region => $attrs->{credit_card}{billing_address}{region},
            address_country_name => $attrs->{credit_card}{billing_address}{country_name},
            cardholder_name => $attrs->{credit_card}{cardholder_name},
            credit_card_expiration_date => $attrs->{credit_card}{expiration_date},
            credit_card_number => $attrs->{credit_card}{number},
        };
    }
}

my $unique_company = "company" . generate_unique_integer();
my $unique_token = "token" . generate_unique_integer();
my $result = create_customer($unique_company, $unique_token);
validate_result($result, 'customer created successfully')
    or BAIL_OUT('Cannot create customer');

my $customer = WebService::Braintree::Customer->find($result->customer->id);

subtest "find customer with all matching fields" => sub {
    my $criteria = make_search_criteria($unique_company, $unique_token);
    my $search_result = perform_search(Customer => $criteria);
    validate_result($search_result) or return;

    not_ok $search_result->is_empty;
    is $search_result->first->credit_cards->[0]->last_4, cc_last4($criteria->{credit_card_number});
};

subtest "can find duplicate credit cards given payment method token" => sub {
    my $unique_company1 = "company" . generate_unique_integer();
    my $unique_token1 = "token" . generate_unique_integer();
    my $customer1 = create_customer($unique_company1, $unique_token1)->customer;

    my $unique_company2 = "company" . generate_unique_integer();
    my $unique_token2 = "token" . generate_unique_integer();
    my $customer2 = create_customer($unique_company2, $unique_token2)->customer;

    my $search_result = WebService::Braintree::Customer->search(sub {
        my $search = shift;
        $search->payment_method_token_with_duplicates->is($customer1->credit_cards->[0]->token);
    });

    not_ok $search_result->is_empty;
    ok grep { $_ eq $customer1->id } @{$search_result->ids};
    ok grep { $_ eq $customer2->id } @{$search_result->ids};
};

subtest "can search on text fields" => sub {
    my $search_result = WebService::Braintree::Customer->search(sub {
        my $search = shift;
        $search->first_name->contains("NotIn");
    });

    not_ok $search_result->is_empty;
    is $search_result->first->first_name, $customer->first_name;
};

subtest "can search on credit card number (partial match)" => sub {
    my $last4 = cc_last4(make_search_criteria()->{credit_card_number});
    my $search_result = WebService::Braintree::Customer->search(sub {
        my $search = shift;
        $search->credit_card_number->ends_with($last4);
    });

    not_ok $search_result->is_empty;

    ok grep { $_->last_4 eq $last4 } @{$search_result->first->credit_cards};
};

subtest "can search on ids (multiple values)" => sub {
    my $search_result = WebService::Braintree::Customer->search(sub {
        my $search = shift;
        $search->ids->in([$customer->id]);
    });

    not_ok $search_result->is_empty;
    is $search_result->first->id, $customer->id;
};

subtest "can search on created_at (range field)" => sub {
    my $unique_company = "company" . generate_unique_integer();
    my $unique_token = "token" . generate_unique_integer();

    my $result = create_customer($unique_company, $unique_token);
    validate_result($result) or return;

    my $new_customer = WebService::Braintree::Customer->find($result->customer->id);
    my $search_result = WebService::Braintree::Customer->search(sub {
        my $search = shift;
        my $one_minute = DateTime::Duration->new(minutes => 1);
        $search->created_at->min($new_customer->created_at - $one_minute);
    });

    not_ok $search_result->is_empty;
    ok grep { $_ eq $new_customer->id } @{$search_result->ids};
};

subtest "can search on address (text field)" => sub {
    my $unique_company = "company" . generate_unique_integer();
    my $unique_token = "token" . generate_unique_integer();
    my $result = create_customer($unique_company, $unique_token);
    validate_result($result) or return;

    my $new_customer = WebService::Braintree::Customer->find($result->customer->id);
    my $search_result = WebService::Braintree::Customer->search(sub {
        my $search = shift;
        $search->address_street_address->is("1 E Main St");
        $search->address_first_name->is("Thomas");
        $search->address_last_name->is("Otool");
        $search->address_extended_address->is("Suite 3");
        $search->address_locality->is("Chicago");
        $search->address_region->is("Illinois");
        $search->address_postal_code->is("60622");
        $search->address_country_name->is("United States of America");
    });

    not_ok $search_result->is_empty;
    ok grep { $_ eq $new_customer->id } @{$search_result->ids};
};

subtest "gets all customers" => sub {
    my $customers = WebService::Braintree::Customer->all;
    ok scalar @{$customers->ids} > 1;
};

done_testing();
