use strict;
use warnings;

use Test::More tests => 6;

use lib 'lib';

use Text::Password::SHA;
my $passwd = Text::Password::SHA->new();

my ( $raw, $hash ) = $passwd->generate();

note('with SHA512');
like $raw, qr/^[!-~]{8}$/, "generated raw passwd: $raw";                # 1
unlike $raw, qr/[0Oo1Il|!2Zz5sS\$6b9qCcKkUuVvWwXx.,:;~\-^'"`]/, "is readable: $raw"; # 2
like $hash, qr/^[!-~]+$/, "generated hash: $hash";                      # 3
is ($passwd->verify( $raw, $hash ), 1, "verified: $raw" );              # 4

( $raw, $hash ) = ( '{fAey4HR', '$5$qiw{V84t$VtRUajh5FQq4l4m3Nx3hvNIgLZLY/YldIqodkMmWz14' );
note('with SHA256');
note('raw password is ' . $raw );
note('hash strings is ' . $hash );
is ($passwd->verify( $raw, $hash ), 1, "verified: $raw" );              # 5

( $raw, $hash ) = ( 'Py3[jJmr', '2167de0e8512b50e79e73c8ce8663a79eb461869' );
note('with SHA1');
note('raw password is ' . $raw );
note('hash strings is ' . $hash );
is ($passwd->verify( $raw, $hash ), 1, "verified: $raw" );              # 6

done_testing;
