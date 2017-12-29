use strict;
use warnings;

use Test::More tests => 8;

use lib 'lib';

use_ok 'Text::Password::SHA';                                           # 1
my $pwd = new_ok('Text::Password::SHA');                                # 2

my ( $raw, $hash ) = $pwd->generate();
 like $pwd->encrypt($raw), qr/^\$6\$([!-~]{1,8})\$[!-~]{86}$/,          # 3
"succeed to encrypt  with SHA512 from raw password";
is $pwd->verify( $raw, $hash ), 1, "succeed to verify with SHA512";     # 4

 is $pwd->verify( $pwd->nonce(), $hash ), '',                           # 5
"fail to verify with random strings";
 is $pwd->verify( '', $hash ), '',                                      # 6
"fail to verify with empty string";

( $raw, $hash ) = ( '{fAey4HR', '$5$qiw{V84t$VtRUajh5FQq4l4m3Nx3hvNIgLZLY/YldIqodkMmWz14' );
is ($pwd->verify( $raw, $hash ), 1, "succeed to verify with SHA256" );  # 7

( $raw, $hash ) = ( 'Py3[jJmr', '2167de0e8512b50e79e73c8ce8663a79eb461869' );
is ($pwd->verify( $raw, $hash ), 1, "succeed to verify with SHA1" );    # 8

done_testing();
