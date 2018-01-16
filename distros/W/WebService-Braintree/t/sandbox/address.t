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
use WebService::Braintree::TestHelper qw/sandbox/;

my $customer_instance = WebService::Braintree::Customer->new;
my $customer_result = $customer_instance->create({
    first_name => "Walter",
    last_name => "Weatherman",
});
validate_result($customer_result);
my $customer = $customer_result->customer;

subtest "create" => sub {
    my $result = WebService::Braintree::Address->create({
        customer_id => $customer->id,
        first_name => "Walter",
        last_name => "Weatherman",
        company => "The Bluth Company",
        street_address => "123 Fake St",
        extended_address => "Suite 403",
        locality => "Chicago",
        region => "Illinois",
        postal_code => "60622",
        country_code_alpha2 => "US",
    });
    validate_result($result) or return;

    is $result->address->street_address, "123 Fake St";
    is $result->address->full_name, "Walter Weatherman";
};

subtest "Create with a bad customer ID" => sub {
    should_throw("NotFoundError", sub {
        WebService::Braintree::Address->create({
            customer_id => "foo",
            first_name => "walter",
        });
    });
};

subtest "Create without any fields"  => sub {
    my $result = WebService::Braintree::Address->create({
        customer_id => $customer->id,
    });
    invalidate_result($result) or return;

    ok(scalar @{$result->errors->for('address')->deep_errors} > 0, "has at least one error on address");
    is($result->message, "Addresses must have at least one field filled in.", "Address error");
};

subtest "with a customer" => sub {
    my $create_result = WebService::Braintree::Address->create({
        customer_id => $customer->id,
        first_name => "Walter",
    });
    validate_result($create_result) or return;
    my $address = $create_result->address;

    subtest "find" => sub {
        my $address = WebService::Braintree::Address->find(
            $customer->id,
            $address->id,
        );
        is $address->first_name, "Walter";
    };

    subtest "not found" =>  sub {
        should_throw("NotFoundError", sub {
            WebService::Braintree::Address->find("not_found", "dne");
        }, "Catches Not Found");
    };

    subtest "Update" => sub {
        my $result = WebService::Braintree::Address->update(
            $customer->id,
            $address->id,
            { first_name => "Ivar" },
        );
        validate_result($result) or return;

        is $result->address->first_name, "Ivar";
    };

    subtest "Update non-existant" => sub {
        should_throw "NotFoundError", sub {
            WebService::Braintree::Address->update("abc", "123");
        };
    };

    subtest "delete existing" => sub {
        my $create = WebService::Braintree::Address->create({
            customer_id => $customer->id,
            first_name => "Ivar",
            last_name => "Jacobson",
        });
        validate_result($create) or return;

        my $result = WebService::Braintree::Address->delete(
            $customer->id,
            $create->address->id,
        );
        validate_result($result) or return;

        should_throw "NotFoundError", sub {
            WebService::Braintree::Address->update(
                $customer->id,
                $create->address->id,
            );
        };
    };
};

done_testing();
