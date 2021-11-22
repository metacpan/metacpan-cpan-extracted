use 5.012;
use strict;
use Test::More;

if (!$ENV{TEST_SIGNATURE}) {
    plan skip_all =>
      "Set the environment variable TEST_SIGNATURE to enable this test.";
}
elsif (!eval { require Module::Signature; 1 }) {
    plan skip_all =>
      "Next time around, consider installing Module::Signature, ".
      "so you can verify the integrity of this distribution.";
}
elsif ( !-e 'SIGNATURE' ) {
    plan skip_all => "SIGNATURE not found";
}
elsif ( -s 'SIGNATURE' == 0 ) {
    plan skip_all => "SIGNATURE file empty";
}
elsif (!eval { find_keyserver(); 1; }) {
    plan skip_all => "Cannot connect to the keyserver to check module ".
                     "signature";
}
else {
    plan tests => 1;
}

sub find_keyserver {
    require Socket;
    for my $server ( 'pool.sks-keyservers.net' , 'hkps.pool.sks-keyservers.net', 'pgp.mit.edu') {
        next unless Socket::inet_aton( $server );
        $Module::Signature::KeyServer = $server;
        last;
    }
}

my $ret = Module::Signature::verify();
SKIP: {
    skip "Module::Signature cannot verify", 1
      if $ret eq Module::Signature::CANNOT_VERIFY();

    cmp_ok $ret, '==', Module::Signature::SIGNATURE_OK(), "Valid signature";
}
