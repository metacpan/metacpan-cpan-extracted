use strict;
use warnings;

use Test::More tests => 3;

use lib 'lib';

use Text::Password::AutoMigration;
my $pwd = Text::Password::AutoMigration->new();
my ( $raw, $hash ) = $pwd->generate();

 is $pwd->verify( $raw, $pwd->nonce() ), undef,                         # 1
"fail to verify with wrong hash";

local $SIG{__WARN__} = sub {
    like $_[0],                                                         # 2
    qr/^Text::Password::AutoMigration doesn't allow any Wide Characters or white spaces/,
    "succeed to catch unvalid data.";
};

is $pwd->verify( $raw . "\n", $hash ), undef,                           # 3
"fail to verify with wrong hash";


done_testing();
