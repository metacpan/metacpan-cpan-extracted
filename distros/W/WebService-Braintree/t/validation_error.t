#!/usr/bin/env perl
use lib qw(lib t/lib);
use WebService::Braintree;
use WebService::Braintree::TestHelper;
use Test::More;

BEGIN { use_ok('WebService::Braintree::ValidationError') };

subtest "initialize" => sub {
    my $error = WebService::Braintree::ValidationError->new(attribute => "some model attribute", code => 1, message => "bad juju");
    is($error->attribute, "some model attribute");
    is($error->code, 1);
    is($error->message, "bad juju");
};

done_testing();
