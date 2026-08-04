use strict;
use warnings;
use Test::More tests => 2;
use XML::Sig;

# verify() must not return true unless a signature was actually verified.
# Signatures skipped before any cryptographic check used to fall through
# to an unconditional "return 1".

my $CERT = 't/rsa.cert.pem';
my $KEY  = 't/rsa.private.key';

my $signed = XML::Sig->new({ key => $KEY, cert => $CERT })
    ->sign('<Document><Claim ID="legit">low privilege</Claim></Document>');

ok(XML::Sig->new({ cert => $CERT })->verify($signed), 'signed document verifies');

# Rewrite the claim and rename the element it was signed under, leaving the
# Reference URI pointing at nothing, then duplicate the Signature so more
# than one is present.  Every signature is now skipped before it is checked.
(my $forged = $signed) =~ s{>low privilege<}{>I am an admin<};
$forged =~ s{ID="legit"}{ID="other"};

$forged =~ s{(<dsig:Signature\b.*</dsig:Signature>)}{$1$1}s;
ok(!XML::Sig->new({ cert => $CERT })->verify($forged),
    'document with no verifiable signature is rejected');
