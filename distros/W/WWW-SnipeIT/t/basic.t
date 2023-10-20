use Modern::Perl;
use Test::More;
use WWW::SnipeIT;

use_ok('WWW::SnipeIT');

my $snipeIT = SnipeIT->new( endpoint => 'http://localhost/api/v1/', accessToken => 'mylongapikey');

isa_ok($snipeIT,'SnipeIT','SnipeIT object');

done_testing;
