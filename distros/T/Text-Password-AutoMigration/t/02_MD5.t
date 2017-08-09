use strict;
use warnings;

use Test::More tests => 3;

use lib 'lib';

use Text::Password::MD5;
my $passwd = Text::Password::MD5->new();

my ( $raw, $hash );

subtest "generate with unix_md5_crypt" => sub {                         # 1
    plan tests => 4;
    ( $raw, $hash ) = $passwd->generate();
    like $raw, qr/^[!-~]{8}$/, "generated raw passwd: $raw";                # 1.1
    unlike $raw, qr/[0Oo1Il|!2Zz5sS\$6b9qCcKkUuVvWwXx.,:;~\-^'"`]/i, "$raw is readable"; # 2.2
    like $hash, qr/^\$1\$[!-~]{1,8}\$[!-~]{22}$/, "generated hash: $hash";  # 1.3
    is ($passwd->verify( $raw, $hash ), 1, "verified: $raw" );              # 1.4
};

eval{ $passwd->verify( $raw, '$1$l1PMyqG!$mNPUHQnly7oLJjt/jb/m/.#' ) };
like $@, qr/^Crypt::PasswdMD5 makes 34bytes hash strings. Your data must be wrong./i,"catch the error with invalid strings";                                        # 2

( $raw, $hash ) = eval{ $passwd->generate(3) };
like $@ , qr/^Text::Password::MD5::generate requires at least 4 length/i, "fail to make too short password";                                                    # 3

done_testing;
