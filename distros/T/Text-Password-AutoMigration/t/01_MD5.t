use strict;
use warnings;
use Test::More tests => 6;

SKIP: {
    eval { require Crypt::PasswdMD5 };
    skip 'Crypt::PasswdMD5 is not installed', 6 if $@;

    use_ok 'Text::Password::MD5';               # 1
    my $pwd = new_ok('Text::Password::MD5');    # 2
    my $m   = $pwd->default;
    my ( $raw, $hash ) = $pwd->generate;

    like $hash,               qr/^\$1\$[ -~]{1,$m}\$[ -~]{22}$/, "succeed to make hash with MD5";  # 3
    like $pwd->encrypt($raw), qr/^\$1\$[ -~]{1,$m}\$[ -~]{22}$/, "succeed to encrypt from raw";    # 4

    subtest "generate with unix_md5_crypt" => sub {                                                # 5
        plan tests => 4;
        ( $raw, $hash ) = $pwd->generate;

        like $hash, qr/^\$1\$[ -~]{1,$m}\$[ -~]{22}$/, "succeed to generated hash with MD5";    # 5.1
        is $pwd->verify( $raw,        $hash ), 1,  "succeed to verify";                         # 5.2
        is $pwd->verify( $pwd->nonce, $hash ), '', "fail to verify with random strings";        # 5.3

        is $pwd->verify( '', $hash ), '', "fail to verify with empty string";                   # 5.4
    };

    subtest "rondom tests" => sub {                                                         # 6
        plan tests => 1000;
        for (1..500){
            ( $raw, $hash ) = $pwd->generate;
            like $hash, qr/^\$1\$[ -~]{1,$m}\$[ -~]{22}$/, "succeed to generate hash with MD5";    # 6.1
            is $pwd->verify( $raw,        $hash ), 1,  "succeed to verify";                         # 6.2
        }
    };
}

done_testing;
