# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper;

subtest "validate params" => sub {
    should_throw("ArgumentError", sub { WebService::Braintree::CreditCard->create({check_it => "out"}) }) ;
};

subtest "builds attributes from build args" => sub {
    my $cc = WebService::Braintree::CreditCard->new(bin => "123456", last_4 => "7890");

    is $cc->bin, "123456";
    is $cc->last_4, "7890";
};

subtest "instance methods" => sub {
    my $cc = WebService::Braintree::CreditCard->new(bin => "123456", last_4 => "7890", default => "0");
    is $cc->masked_number, "123456******7890";
    not_ok $cc->is_default;

    my $default = WebService::Braintree::CreditCard->new(default => 1);
    ok $default->is_default;
};

subtest "throws error if find is passed a blank/empty string" => sub {
    should_throw("NotFoundError", sub { WebService::Braintree::CreditCard->find("") });
    should_throw("NotFoundError", sub { WebService::Braintree::CreditCard->find("  ") });
};

done_testing();
