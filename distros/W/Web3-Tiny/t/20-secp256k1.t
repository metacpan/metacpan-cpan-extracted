use strict;
use warnings;
use Test::More;

use Web3::Tiny::Secp256k1 qw(
    privkey_to_address privkey_to_pubkey sign_hash recover_pubkey verify_hash
);
use Web3::Tiny::Keccak256 qw(keccak256);

# well-known "vanity" addresses for tiny private keys
is(unpack('H*', privkey_to_address(pack('H*', '00' x 31 . '01'))),
    '7e5f4552091a69125d5dfcb7b8c2659029395bdf', 'address for privkey=1');

is(unpack('H*', privkey_to_address(pack('H*', '00' x 31 . '02'))),
    '2b5ad5c4795c026514f8317c7a215e218dccd6cf', 'address for privkey=2');

my $priv = pack('H*', '4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f36231a');
my ($x, $y) = privkey_to_pubkey($priv);
my $addr    = privkey_to_address($priv);
my $hash    = keccak256('hello ethereum');

my ($r, $s, $recid) = sign_hash($hash, $priv);
ok(verify_hash($hash, $r, $s, $x, $y), 'signature verifies against own pubkey');
ok(!verify_hash(keccak256('tampered'), $r, $s, $x, $y), 'tampered hash fails verification');

my ($rx, $ry) = recover_pubkey($hash, $r, $s, $recid);
is($rx, $x, 'recovered pubkey x matches');
is($ry, $y, 'recovered pubkey y matches');

my ($r2, $s2, $recid2) = sign_hash($hash, $priv);
is($r, $r2, 'RFC6979 signing is deterministic (r)');
is($s, $s2, 'RFC6979 signing is deterministic (s)');
is($recid, $recid2, 'RFC6979 signing is deterministic (recid)');

# recovery must work for both parities of recid across several messages
for my $i (1 .. 6) {
    my $h = keccak256("msg$i");
    my ($rr, $ss, $rc) = sign_hash($h, $priv);
    my ($qx, $qy) = recover_pubkey($h, $rr, $ss, $rc);
    is($qx, $x, "recover_pubkey x roundtrip for msg$i (recid=$rc)");
    is($qy, $y, "recover_pubkey y roundtrip for msg$i (recid=$rc)");
}

done_testing;
