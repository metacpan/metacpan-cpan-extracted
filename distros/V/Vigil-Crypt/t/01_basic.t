#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
use Vigil::Crypt;

my $crypt  = Vigil::Crypt->new('a3f1c5e7b9d2f4a6c8e0b2d4f6a8c0e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a2');
my $aad    = 'LarryWalLRocks';
my $test_email = 'badhat_is_a_dumbass@noway.man';
my $test_pwd   = 'Hq2&nD7fXr!Vb5$YmC1zWk8pLgQw$eZ8@RbM4xYjL6s';

my $encrypted_value = $crypt->encrypt($test_email, $aad);
ok(length($encrypted_value) > length($test_email), 'encrypt() works.');

my $decrypted_value = $crypt->decrypt($encrypted_value, $aad);
ok($test_email eq $decrypted_value, 'decrypt() works.');

my $hash = $crypt->hash($test_pwd, $aad);
ok( $hash && $hash ne $test_pwd, 'hash() works.');

ok($crypt->verify_hash($test_pwd, $hash, $aad), 'verify_hash() works');

done_testing();
