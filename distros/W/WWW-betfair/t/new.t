use strict;
use warnings;
use Test::More; 
use Data::Dumper;
use Crypt::CBC;
use 5.10.2;

BEGIN{do {plan skip_all => 'tests not run on install as user credentials are required to test betfair API.'}};

# Prepare cipher
my $key = Crypt::CBC->random_bytes(56);
my $cipher = Crypt::CBC->new(-key    => $key,
                             -cipher => 'Blowfish',
                             -salt   => 1,
                            );

BEGIN{ use_ok('WWW::betfair'); }
ok(my $b = WWW::betfair->new, 'create new betfair object');

    print 'Please enter your betfair username: ';
    chomp( my $username = <STDIN>);
    print 'Please enter your betfair password: ';
    system("stty -echo");
    my $ciphertext = $cipher->encrypt(<STDIN> =~ s/\n$//r);
    system("stty echo");

    # attempt to login
    my $loginResult = $b->login({  username => $username, 
                                   password => $cipher->decrypt($ciphertext),
                                   productId=> 22,
                            });
    ok($loginResult, 'login');
    
SKIP: {
    skip 'as login failed -' . $b->getError, 1 unless $loginResult;

    open (my $HASH, '>>', 'getAllMarketsHash.out');
    open (my $STRING, '>>', 'getAllMarketsString.out');
    ok(say $HASH Dumper($b->getAllMarkets({exchangeId => 1})), 'get all markets');
    
    say $STRING Dumper($b->getHashReceived);
    say $b->getError;

    ok($b->logout, 'logout');
 }

# getPrivateMarkets
# get market profit and loss

done_testing;
