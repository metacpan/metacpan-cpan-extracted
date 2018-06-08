use strict;
use warnings;
use utf8;

use Test::More;

use WebService::RESTCountries;

my $expected;

my $api = WebService::RESTCountries->new;
$api->download();

$expected = 'RESTCountries.json';
is(-e $expected, 1, "expect downloaded file found in $expected");
unlink($expected);

$expected = '/tmp/RESTCountries.json';
$api->download($expected);
is(-e $expected, 1, "expect downloaded file found in $expected");
unlink($expected);

done_testing;
