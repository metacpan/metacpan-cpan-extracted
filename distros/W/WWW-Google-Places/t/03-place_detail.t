#!perl

use 5.006;
use strict; use warnings;
use WWW::Google::Places;
use Test::More tests => 1;

my ($api_key, $sensor, $google);
$api_key = 'Your_API_Key';
$sensor  = 'true';
$google  = WWW::Google::Places->new(api_key=>$api_key, sensor=>$sensor);

eval { $google->details(); };
like($@, qr/details\(\)\: Undefined required parameter/);

done_testing();
