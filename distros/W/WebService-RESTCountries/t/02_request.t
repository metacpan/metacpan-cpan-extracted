use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my ($got, $expect) = ('', '');

my $api = WebService::RESTCountries->new;

$expect = undef;
$got = $api->_request();
is_deeply($got, $expect, 'expect empty response');

done_testing;
