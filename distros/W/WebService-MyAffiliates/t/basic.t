use strict;
use Test::More;
use Test::Exception;
use WebService::MyAffiliates;

my $aff = WebService::MyAffiliates->new(
    user => 'user',
    pass => 'pass',
    host => 'admin.example.com'
);
ok($aff);

throws_ok { $aff->decode_token() } qr/Must pass at least one token/;
throws_ok { $aff->get_affiliate_id_from_token() } qr/Must pass a token to get_affiliate_id_from_token/, 'Throws exception if no token given.';

done_testing;
