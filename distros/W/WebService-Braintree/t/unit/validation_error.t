# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper;

BEGIN { use_ok('WebService::Braintree::ValidationError') };

subtest "initialize" => sub {
    my $error = WebService::Braintree::ValidationError->new(attribute => "some model attribute", code => 1, message => "bad juju");
    is($error->attribute, "some model attribute");
    is($error->code, 1);
    is($error->message, "bad juju");
};

done_testing();
