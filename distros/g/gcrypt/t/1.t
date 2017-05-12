# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test;
BEGIN { plan tests => 15 }; # <--- number of tests
use GCrypt;
ok(1); # If we made it this far, we're ok.

#########################

my $c = new GCrypt::Cipher('aes', 'cbc', 0);
ok(defined $c && $c->isa('GCrypt::Cipher'));
ok($c->keylen == 16);
ok($c->blklen == 16);

$c->setkey(my $key = "the key, the key");

my $p = 'plain text';
my ($e0, $e, $d);
$e0 = pack('H*', 'c796843558cefa157bf108ab79823a5a');
$e = $c->encrypt($p);
ok($e eq $e0) or print STDERR "[",unpack('H*',$e),"]\n";

$c->setiv();
$d = $c->decrypt($e);
ok(substr($d, 0, length $p) eq $p)
  or print STDERR "[",unpack('H*',$d),"]\n";;

$c = new GCrypt::Cipher('aes', 'ecb');
$c->setkey($key);
$e = $c->encrypt($p);
ok($e eq $e0) or print STDERR "[",unpack('H*',$e),"]\n";

$c = new GCrypt::Cipher('twofish');
ok($c->keylen == 32);
ok($c->blklen == 16);
$c->setkey($key);
$c->setiv(my $iv = 'explicit iv');
$e = $c->encrypt($p);
ok($e eq pack('H*', '9c93705d7b3348c73cd2047ce5ecc1a8'))
  or print STDERR "[",unpack('H*',$e),"]\n";
$c->setiv($iv);
$d = $c->decrypt($e);
ok(substr($d, 0, length $p) eq $p)
 or print STDERR "[$d|",unpack('H*',$d),"]\n";

$c = GCrypt::Cipher::new('arcfour');
ok($c->keylen == 16);
ok($c->blklen == 1);
$c->setkey($key);
$e = $c->encrypt($p);
ok($e eq pack('H*', '02a98d20a176729ea7cd'))
  or print STDERR "[",unpack('H*',$e),"]\n";
$c->setkey($key);
$d = $c->decrypt($e);
ok(substr($d, 0, length $p) eq $p)
 or print STDERR "[$d|",unpack('H*',$d),"]\n";
