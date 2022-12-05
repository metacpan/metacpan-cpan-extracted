use strict;
use warnings;

use Test::More tests => 4;

use_ok 'Text::Password::MD5';               # 1
my $pwd = new_ok('Text::Password::MD5');    # 2

my ( $raw, $hash ) = $pwd->generate();
like $pwd->encrypt($raw), qr/^\$1\$[!-~]{1,8}\$[!-~]{22}$/,    # 3

    "succeed to encrypt from raw password";

subtest "generate with unix_md5_crypt" => sub {    # 4
    plan tests => 4;
    ( $raw, $hash ) = $pwd->generate();
    like $hash,                                    # 4.1
        qr/^\$1\$[!-~]{1,8}\$[!-~]{22}$/, "succeed to generated hash with MD5";
    is $pwd->verify( $raw, $hash ), 1, "succeed to verify";    # 4.2
    is $pwd->verify( $pwd->nonce(), $hash ), '',               # 4.3
        "fail to verify with random strings";
    is $pwd->verify( '', $hash ), '',                          # 4.4
        "fail to verify with empty string";
};

done_testing();
