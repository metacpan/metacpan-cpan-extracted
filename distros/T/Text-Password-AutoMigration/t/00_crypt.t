use strict;
use warnings;

use Test::More tests => 11;

use_ok 'Text::Password::CoreCrypt';                                                          # 1
my $pwd = new_ok('Text::Password::CoreCrypt');                                               # 2
like $pwd->nonce(),  qr/^[!-~]{8}$/, "succeed to make nonce with length 8 automatically";    # 3
like $pwd->nonce(4), qr/^[!-~]{4}$/, "succeed to make nonce with length 4";                  # 4

eval { $pwd->nonce(3) };
like $@, qr/^Unvalid length for nonce was set/, "fail to make nonce with enough length";     # 5

eval { $pwd->nonce('wrong') };
like $@, qr/^Unvalid length for nonce was set/, "fail to make nonce without setting digit";    # 6

SKIP: {
    skip "CORE::crypt is not available", 3 unless $pwd->can('CORE::crypt');
    my ( $raw, $hash ) = $pwd->generate;
    like $pwd->encrypt($raw), qr/^[!-~]{13}$/, "succeed to encrypt from raw password";    # 7
    is $pwd->verify( $pwd->nonce, $hash ), '', "fail to verify with wrong password";      # 8

    subtest "generate with CORE::crypt" => sub {                                          # 9
        plan tests => 6;
        my ( $raw, $hash ) = $pwd->generate;
        like $raw,  qr/^[!-~]{8}$/, "succeed to generate raw passwd";                          # 9.1
        like $raw,  qr/^[^0Oo1Il|!2Zz5sS\$6b9qCcKkUuVvWwXx.,:;~\-^'"`]{8}$/, "is readable";    # 9.2
        like $hash, qr/^[!-~]{13}$/, "succeed to generate hash with CORE::crypt";              # 9.3
        is $pwd->verify( $raw,        $hash ), 1,  "succeed to verify";                        # 9.4
        is $pwd->verify( $pwd->nonce, $hash ), '', "fail to verify with random strings";       # 9.5
        is $pwd->verify( '',          $hash ), '', "fail to verify with empty string";         # 9.6
    };
}

subtest "generate unreadable strings" => sub {    #10
    plan tests => 3;
    $pwd->readability(0);
    my ( $raw, $hash ) = $pwd->generate;
    like $raw,  qr/^[!-~]{8}$/,  "succeed to generate raw passwd";    #10.1
    like $hash, qr/^[!-~]{13}$/, "succeed to generate hash";          #10.2
    is $pwd->verify( $raw, $hash ), 1, "succeed to verify";           #10.3
};

my ( $raw, $hash ) = eval { $pwd->generate(3) };
like $@, qr/^Text::Password::CoreCrypt::generate requires at least 4 length/,
    "fail to make too short password";                                #11

done_testing;
