use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';

use Text::Password::AutoMigration;
my $passwd = Text::Password::AutoMigration->new();
my $passwdMD5 = Text::Password::MD5->new();
my $passwdCC = Text::Password::CoreCrypt->new();

my @ok = qw( fail ok );
my ( $raw, $hash, $flag );

( $raw, $hash ) = $passwdCC->generate();
note('with CORE::Crypt');
note('generated raw password is ' . $raw );
note('generated hash strings is ' . $hash );

$flag = $passwd->verify( $raw, $hash );
like $flag, qr/^\$6\$[!-~]{1,8}\$[!-~]{86}$/, "verify: " . $ok[$flag ne '']; # 1

( $raw, $hash ) = $passwdMD5->generate();
note('with MD5');
note('generated raw password is ' . $raw );
note('generated hash strings is ' . $hash );

$flag = $passwd->verify( $raw, $hash );
like $flag, qr/^\$6\$[!-~]{1,8}\$[!-~]{86}$/, "verify: " . $ok[$flag ne '']; # 2

( $raw, $hash ) = $passwd->generate();
note('with SHA');
note('generated raw password is ' . $raw );
note('generated hash strings is ' . $hash );

$flag = $passwd->verify( $raw, $hash );
like $flag, qr/^\$6\$[!-~]{1,8}\$[!-~]{86}$/, "verify: " . $ok[$flag ne '']; # 3

$passwd->default(12);
( $raw, $hash ) = $passwd->generate();
note('12 length raw password');
note('generated raw password is ' . $raw );

is length($raw), 12, "The length is 12";                                    # 4

$passwd->migrate(0); # force to return Boolean with verify()
$flag = $passwd->verify( $raw, $hash );
is $flag, 1, "verify: " . $ok[$flag];                                       # 5

done_testing();
