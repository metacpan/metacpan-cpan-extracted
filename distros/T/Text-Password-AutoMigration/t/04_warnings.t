use strict;
use warnings;

use Test::More tests => 3;

use Text::Password::AutoMigration;
my $pwd = Text::Password::AutoMigration->new;
my ( $raw, $hash ) = $pwd->generate;

local $SIG{__WARN__} = sub {
    like $_[0], qr|^Text::Password::SHA doesn't support this hash:|,
        "succeed to catch unvalid data.";    # 0
};

is $pwd->verify( $raw,        $pwd->nonce ), 0, "fail to verify with wrong hash";    # 1
is $pwd->verify( $raw . "\n", $hash ),       0, "fail to verify with wrong hash";    # 2

done_testing;
