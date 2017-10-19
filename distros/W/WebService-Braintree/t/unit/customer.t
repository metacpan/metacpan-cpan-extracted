# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::TestHelper;

subtest 'validate params' => sub {
    should_throw('ArgumentError', sub {
        WebService::Braintree::Customer->create({invalid_param => 'value'});
    });
};

subtest 'throws notFoundError if find is passed an empty string' => sub {
    should_throw('NotFoundError', sub { WebService::Braintree::Customer->find('') });
    should_throw('NotFoundError', sub { WebService::Braintree::Customer->find('  ') });
};

done_testing();
