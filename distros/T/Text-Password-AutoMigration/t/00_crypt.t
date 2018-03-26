use strict;
use warnings;

use Test::More tests => 11;

use lib 'lib';

use_ok 'Text::Password::CoreCrypt';                                     # 1
my $pwd = new_ok('Text::Password::CoreCrypt');                          # 2

 like $pwd->nonce(), qr/^[!-~]{8}$/,                                    # 3
"succeed to make nonce with length 8 automatically";
 like $pwd->nonce(4), qr/^[!-~]{4}$/,                                   # 4
"succeed to make nonce with length 4";
eval{ $pwd->nonce(3) };
 like $@, qr/^Unvalid length for nonce was set/,                        # 5
"fail to make nonce with enough length";
eval{ $pwd->nonce('wrong') };
 like $@, qr/^Unvalid length for nonce was set/,                        # 6
"fail to make nonce without setting digit";

my ( $raw, $hash ) = $pwd->generate();
 like $pwd->encrypt($raw), qr/^[!-~]{13}$/,                             # 7
"succeed to encrypt from raw password";

 is $pwd->verify( $pwd->nonce(), $hash ), '',                           # 8
"fail to verify with wrong password";

subtest "generate with CORE::crypt" => sub {                            # 9
    plan tests => 6;
    my ( $raw, $hash ) = $pwd->generate();
    like $raw, qr/^[!-~]{8}$/, "succeed to generate raw passwd";        # 9.1
    like $raw, qr/^[^0Oo1Il|!2Zz5sS\$6b9qCcKkUuVvWwXx.,:;~\-^'"`]{8}$/, # 9.2
    "is readable";
     like $hash, qr/^[!-~]{13}$/,                                       # 9.3
    "succeed to generate hash with CORE::crypt";
    is $pwd->verify( $raw, $hash ), 1, "succeed to verify";             # 9.4
     is $pwd->verify( $pwd->nonce(), $hash ), '',                       # 9.5
    "fail to verify with random strings";
     is $pwd->verify( '', $hash ), '',                                  # 9.6
    "fail to verify with empty string";
};

subtest "generate unreadable strings" => sub {                          #10
    plan tests => 3;
    $pwd->readability(0);
    my ( $raw, $hash ) = $pwd->generate();
    like $raw, qr/^[!-~]{8}$/, "succeed to generate raw passwd";        #10.1
    like $hash, qr/^[!-~]{13}$/, "succeed to generate hash";            #10.2
    is $pwd->verify( $raw, $hash ), 1, "succeed to verify";             #10.3
};

( $raw, $hash ) = eval{ $pwd->generate(3) };
 like $@ ,
 qr/^Text::Password::CoreCrypt::generate requires at least 4 length/i,
"fail to make too short password";                                      #11

done_testing();
