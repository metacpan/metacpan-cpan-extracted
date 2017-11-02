use strict;
use warnings;

use Test::More tests => 7;

use lib 'lib';

use_ok 'Text::Password::AutoMigration';                                 # 1
my $pwd = new_ok('Text::Password::AutoMigration');                      # 2
my $pwd_MD5 = Text::Password::MD5->new();
my $pwd_CC = Text::Password::CoreCrypt->new();

my @ok = qw( fail ok );
my ( $raw, $hash, $flag );

( $raw, $hash ) = $pwd_CC->generate();
note('generated hash strings with CORE::Crypt is ' . $hash );

$flag = $pwd->verify( $raw, $hash );
 like $flag, qr/^\$6\$[!-~]{1,8}\$[!-~]{86}$/,                          # 3
"verify: " . $ok[ $flag ne '' ];

( $raw, $hash ) = $pwd_MD5->generate();
note('generated hash strings with MD5 is ' . $hash );

$flag = $pwd->verify( $raw, $hash );
 like $flag, qr/^\$6\$[!-~]{1,8}\$[!-~]{86}$/,                          # 4
"verify: " . $ok[ $flag ne '' ];

( $raw, $hash ) = $pwd->generate();
note('generated hash strings with SHA512 is ' . $hash );

$flag = $pwd->verify( $raw, $hash );
 like $flag, qr/^\$6\$[!-~]{1,8}\$[!-~]{86}$/,                          # 5
"verify: " . $ok[ $flag ne '' ];

$pwd->default(12);
( $raw, $hash ) = $pwd->generate();
is length($raw), 12, "succeed to generate raw password with 12 length"; # 6

$pwd->migrate(0); # force to return Boolean with verify()
$flag = $pwd->verify( $raw, $hash );
is $flag, 1, "verify: " . $ok[$flag];                                   # 7

done_testing();
