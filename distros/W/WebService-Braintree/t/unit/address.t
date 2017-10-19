# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree::TestHelper;

subtest "validation" => sub {
    should_throw("ArgumentError", sub {
        WebService::Braintree::Address->create({customer_id => "cutomer_id", invalid_key => "foo"});
    });
};

subtest "instance methods" => sub {
    my $address = WebService::Braintree::Address->new(first_name => "Walter", last_name => "Weatherman");
    is $address->full_name, "Walter Weatherman";
};

subtest "throws error on find if passed empty string for customer or address id" => sub {
    should_throw("NotFoundError", sub { WebService::Braintree::Address->find("", "adfs671") });
    should_throw("NotFoundError", sub { WebService::Braintree::Address->find("   ", "asdf") });
    should_throw("NotFoundError", sub { WebService::Braintree::Address->find("iaddf", "") });
    should_throw("NotFoundError", sub { WebService::Braintree::Address->find("iaddf", "  ") });
};

done_testing();
