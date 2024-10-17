use strict;
use warnings;

use Test::More tests => 7;

use_ok 'Text::Password::AutoMigration';               # 1
my $pwd = new_ok('Text::Password::AutoMigration');    # 2
my $m   = $pwd->default;
my @ok  = qw( fail ok );
my ( $raw, $hash, $flag );

( $raw, $hash ) = $pwd->generate;

note( 'generated hash strings with CORE::Crypt is ', $hash );

subtest 'verify with CORE::Crypt 100 times' => sub {    # 3
    plan tests => 100;
    foreach ( 1 .. 100 ) {
        $flag = $pwd->verify( $raw, $hash );
        like $flag, qr|^\$6\$[ -~]{1,$m}\$[\w/\.]{86}$|, "verify: " . $flag;
    }
};

SKIP: {
    eval { require Crypt::PasswdMD5 };
    skip 'Crypt::PasswdMD5 is not installed', 1 if $@;

    ( $raw, $hash ) = $pwd->Text::Password::MD5::generate;

    note( 'generated hash strings with MD5 is', $hash );

    subtest 'verify with MD5 100 times' => sub {    # 4
        plan tests => 100;
        foreach ( 1 .. 100 ) {
            $flag = $pwd->verify( $raw, $hash );
            like $flag, qr|^\$6\$[ -~]{1,$m}\$[\w/\.]{86}$|, "verify: " . $flag;
            ( $raw, $hash ) = $pwd->Text::Password::MD5::generate;

        }
    };
}

( $raw, $hash ) = $pwd->generate;

note( 'generated hash strings with SHA512 is ' . $hash );

subtest 'verify with SHA512 100 times' => sub {    # 5
    plan tests => 2000;
    foreach ( 1 .. 1000 ) {
        $flag = $pwd->verify( $raw, $hash );
        like $flag, qr|^\$6\$[ -~]{1,$m}\$[\w/\.]{86}$|, "verify: " . $flag;    # 5.1
        isnt $flag, $hash;                                                      # 5.2
    }
};

my $longer = 16;
$pwd->default($longer);

( $raw, $hash ) = $pwd->generate;

is length($raw), $longer, "succeed to generate raw password with $longer length";    # 6

$pwd->migrate(0);                                                                    # force to return Boolean with verify()

$flag = $pwd->verify( $raw, $hash );
is $flag, 1, "verify: " . $ok[$flag];                                                # 7

done_testing;
