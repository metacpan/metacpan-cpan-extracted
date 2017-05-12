use strict;
use warnings;
use Test::More; 
use Crypt::CBC;

# Skip all tests as authentication is required to test
BEGIN{do {plan skip_all => 'tests not run on install as user credentials are required to test betfair API.'}};

# Prepare cipher
my $key = Crypt::CBC->random_bytes(56);
my $cipher = Crypt::CBC->new(-key    => $key,
                             -cipher => 'Blowfish',
                             -salt   => 1,
                            );

use_ok('WWW::betfair');
ok(my $b = WWW::betfair->new, 'create new betfair object');

SKIP: {
    print 'WWW::betfair needs to connect to the betfair API to fully test the library is working. The tests are all read-only betfair services and will not affect your betfair account. This will require your betfair username and password to start a session with betfair and an active internet connection. Would you like to run these tests? [y/n] ';

    chomp (my $response = <STDIN>);
    skip '- user decided not to run', 17 unless lc $response eq 'y';
    print 'Please enter your betfair username: ';
    chomp( my $username = <STDIN>);
    print 'Please enter your betfair password: ';
    system("stty -echo");
    my $ciphertext = $cipher->encrypt(<STDIN> =~ s/\n$//r);
    system("stty echo");

    # attempt to login
    my $loginResult = $b->login({  username => $username, 
                                   password => $cipher->decrypt($ciphertext),
                            });
    ok($loginResult, 'login');
    skip 'as login failed -' . $b->getError, 16 unless $loginResult;
    ok($b->getError, 'getError');
    ok($b->getHashReceived, 'getHashReceived');
    ok($b->getXMLReceived, 'getXMLReceived');
    ok($b->getXMLSent, 'getXMLSent');
    ok($b->keepAlive, 'keepAlive');
    ok($b->getActiveEventTypes, 'getActiveEventTypes');
    ok($b->getEvents({eventParentId => 1}), 'getEvents - 1');
    ok($b->getActiveEventTypes, 'getActiveEventTypes');
    ok($b->getAllEventTypes, 'getAllEventTypes');
    ok($b->getAllMarkets({exchangeId => 1}), 'getAllMarkets');
    ok($b->getPaymentCard, 'getPaymentCard');
    ok($b->getSubscriptionInfo, 'getSubscriptionInfo');
    ok($b->getAccountFunds({exchangeId => 1}), 'getAccountFunds');
    ok($b->getAllCurrencies, 'getAllCurrencies');
    ok($b->getAllCurrenciesV2, 'getAllCurrenciesV2');
    ok($b->logout, 'logout');
}

done_testing;
