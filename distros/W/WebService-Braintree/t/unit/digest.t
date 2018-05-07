# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

my $query_string = 'one=1&two=2&http_status=200';
my $private_key = 'integration_private_key';
my $expected_hash = '3970ae558c51cf6f54340b5b1842d47ba1f5a19e';

use WebService::Braintree::Digest qw(hexdigest);

is(
    hexdigest($private_key, $query_string),
    $expected_hash,
    'Braintree digest works',
);

done_testing();
