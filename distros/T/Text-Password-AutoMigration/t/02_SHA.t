use strict;
use warnings;

use Test::More tests => 12;
SKIP: {
    eval { require Digest::SHA };
    skip 'Digest::SHA is not installed', 12 if $@;

    use_ok 'Text::Password::SHA';               # 1
    my $pwd = new_ok('Text::Password::SHA');    # 2
    my $m   = $pwd->default;

    my ( $raw, $hash ) = $pwd->generate;

    like $pwd->encrypt($raw), qr|^\$6\$[ -~]{1,$m}\$[\w/\.]{86}$|, "encrypt with SHA512 from raw"; # 3
    is $pwd->verify( $raw,        $hash ), 1,  "succeed to verify with SHA512";                    # 4
    is $pwd->verify( $pwd->nonce, $hash ), '', "fail to verify with random strings";               # 5

    ( $raw, $hash ) = ( '{fAey4HR', '$5$qiw{V84t$VtRUajh5FQq4l4m3Nx3hvNIgLZLY/YldIqodkMmWz14' );
    is( $pwd->verify( $raw, $hash ), 1, "succeed to verify with SHA256" );                         # 6

    ( $raw, $hash ) = ( 'Py3[jJmr', '2167de0e8512b50e79e73c8ce8663a79eb461869' );
    is( $pwd->verify( $raw, $hash ), 1, "succeed to verify with SHA1" );                           # 7

    $hash = eval { $pwd->encrypt("few") };
    like $@,
        qr/^Text::Password::SHA requires a strings longer than at least 4/,
        "fail to encrypt too short password";                                                      # 8

    $hash = eval { $pwd->encrypt("f e w") };
    is $@, '', "succeed to encrypt the strings with space";                                        # 9

    eval { $hash = $pwd->encrypt("f e\tw") };
    like $@, qr/^Text::Password::SHA doesn't allow any Wide Characters or control codes/,

        "fail to encrypt with forbidden charactors";                                               #10

    subtest "generate with SHA-512" => sub {                                                       #11
        plan tests => 3;
        my ( $raw, $hash ) = $pwd->generate;

        like $hash, qr|^\$6\$[ -~]{1,$m}\$[\w/\.]{86}$|, "succeed to generate hash with SHA512";   # 11.1
        is $pwd->verify( $raw,        $hash ), 1,  "succeed to verify";                            # 11.2
        is $pwd->verify( $pwd->nonce, $hash ), '', "fail to verify with random strings";           # 11.3
    };

    subtest "rondom tests" => sub {                                                         # 12
        plan tests => 1000;
        for (1..500){
            ( $raw, $hash ) = $pwd->generate;
            like $hash, qr|^\$6\$[ -~]{1,$m}\$[\w/\.]{86}$|, "succeed to generate hash with SHA512";    # 12.1
            is $pwd->verify( $raw, $hash ), 1,  "succeed to verify";                                    # 12.2
        }
    };
}

done_testing;
