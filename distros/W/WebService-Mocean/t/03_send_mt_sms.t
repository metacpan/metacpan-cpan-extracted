use strict;
use warnings;
use utf8;

use Test::More;

use WebService::Mocean;

my ($response, $expect) = ('', '');
my ($to, $from, $text) = ('60123456789', 'Your Company', 'Hello');

my $mocean_api = WebService::Mocean->new(api_key => 'foo', api_secret => 'bar');

$response = $mocean_api->send_mt_sms($to, $from, $text);
$expect = {
    'err_msg' => 'Authorization+failed',
    'status' => '1'
};
is_deeply($response, $expect, 'expect unknown request response');

done_testing;
