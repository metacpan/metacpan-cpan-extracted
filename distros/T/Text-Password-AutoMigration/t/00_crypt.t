use strict;
use warnings;

use Test::More tests => 9;

use lib 'lib';

use_ok 'Text::Password::CoreCrypt';                                     # 1
my $pwd = new_ok('Text::Password::CoreCrypt');                          # 2

 like $pwd->nonce(), qr/^[!-~]{8}$/,                                    # 3
"succeed to make nonce with length 8 automatically";
 like $pwd->nonce(4), qr/^[!-~]{4}$/,                                   # 4
"succeed to make nonce with length 4";

my ( $raw, $hash ) = $pwd->generate();
 like $pwd->encrypt($raw), qr/^[!-~]{13}$/,                             # 5
"succeed to encrypt from raw password";

subtest "generate with CORE::crypt" => sub {                            # 6
    plan tests => 6;
    my ( $raw, $hash ) = $pwd->generate();
    like $raw, qr/^[!-~]{8}$/, "succeed to generate raw passwd";        # 6.1
    like $raw, qr/^[^0Oo1Il|!2Zz5sS\$6b9qCcKkUuVvWwXx.,:;~\-^'"`]{8}$/, # 6.2
    "is readable";
     like $hash, qr/^[!-~]{13}$/,                                       # 6.3
    "succeed to generate hash with CORE::crypt";
    is $pwd->verify( $raw, $hash ), 1, "succeed to verify";             # 6.4
     is $pwd->verify( $pwd->nonce(), $hash ), '',                       # 6.5
    "fail to verify with random strings";
     is $pwd->verify( '', $hash ), '',                                  # 6.6
    "fail to verify with empty string";
};

subtest "generate unreadable strings" => sub {                          # 7
    plan tests => 3;
    $pwd->readability(0);
    my ( $raw, $hash ) = $pwd->generate();
    like $raw, qr/^[!-~]{8}$/, "succeed to generate raw passwd";        # 7.1
    like $hash, qr/^[!-~]{13}$/, "succeed to generate hash";            # 7.2
    is $pwd->verify( $raw, $hash ), 1, "succeed to verify";             # 7.3
};

eval{ $pwd->verify( $raw, '$1$l1PMyqG!$mNPUHQnly7oLJjt/jb/m/.' ) };
 like $@,                                                               # 8
 qr/^CORE::crypt makes 13bytes hash strings\. Your data must be wrong\./i,
"fail to verify with invalid strings";

( $raw, $hash ) = eval{ $pwd->generate(3) };
 like $@ ,
 qr/^Text::Password::CoreCrypt::generate requires at least 4 length/i,
"fail to make too short password";                                      # 9

done_testing();
