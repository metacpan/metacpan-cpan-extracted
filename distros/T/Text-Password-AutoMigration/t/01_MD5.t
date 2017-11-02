use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';

use_ok 'Text::Password::MD5';                                           # 1
my $pwd = new_ok('Text::Password::MD5');                                # 2

my ( $raw, $hash ) = $pwd->generate();
 like $pwd->encrypt($raw), qr/^\$1\$[!-~]{1,8}\$[!-~]{22}$/,            # 3
"succeed to encrypt from raw password";


subtest "generate with unix_md5_crypt" => sub {                         # 4
    plan tests => 2;
    my ( $raw, $hash ) = $pwd->generate();
     like $hash,                                                        # 4.1
    qr/^\$1\$[!-~]{1,8}\$[!-~]{22}$/, "succeed to generated hash with MD5";
    is ($pwd->verify( $raw, $hash ), 1, "succeed to verify" );          # 4.2
};

eval{ $pwd->verify( $raw, '$1$l1PMyqG!$mNPUHQnly7oLJjt/jb/m/.#' ) };
 like $@,                                                               # 5
 qr/^Crypt::PasswdMD5 makes 34bytes hash strings. Your data must be wrong./i,
"catch the error with invalid strings";

done_testing();
