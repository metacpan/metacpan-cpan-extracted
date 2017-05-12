
use strict;
use Test;
BEGIN { plan tests => 43, todo => [38] };

use X500::DN;
ok(1); # If we made it this far, we're ok.

### Tests for X500::DN follow

my $s;
my $rdn;
my $dn;

# Tests 2-4: empty DN
$dn = X500::DN->ParseRFC2253 ('');
ok ($dn && $dn->getRDNs(), 0);
ok ($dn && $dn->getRFC2253String(), '');
ok ($dn && $dn->getX500String(), '{}');

# Test 5-9: one RDN, RDN type is oid
$dn = X500::DN->ParseRFC2253 ('1.4.9=2001');
ok ($dn && $dn->getRDNs(), 1);
$rdn = $dn && $dn->getRDN (0);
ok ($rdn && $rdn->getAttributeTypes(), 1);
ok ($rdn && ($rdn->getAttributeTypes())[0], '1.4.9');
ok ($rdn && $rdn->getAttributeValue ('1.4.9'), '2001');
ok ($dn && $dn->getRFC2253String(), '1.4.9=2001');

# Tests 10-12: two RDNs
$dn = X500::DN->ParseRFC2253 ('cn=Nemo,c=US');
ok ($dn && $dn->getRDNs(), 2);
ok ($dn && $dn->getRFC2253String(), 'cn=Nemo, c=US');
ok ($dn && $dn->hasMultivaluedRDNs, 0);

# Tests 13-14: three RDNs
$dn = X500::DN->ParseRFC2253 ('cn=John Doe, o=Acme, c=US');
ok ($dn && $dn->getRDNs(), 3);
ok ($dn && $dn->getRFC2253String(), 'cn=John Doe, o=Acme, c=US');

# Tests 15-16: escaped comma
$dn = X500::DN->ParseRFC2253 ('cn=John Doe, o=Acme\\, Inc., c=US');
ok ($dn && $dn->getRDNs(), 3);
ok ($dn && $dn->getRDN (1)->getAttributeValue ('o'), 'Acme, Inc.');

# Tests 17-18: escaped space
$dn = X500::DN->ParseRFC2253 ('x=\\ ');
ok ($dn && $dn->getRDNs(), 1);
$rdn = $dn && $dn->getRDN (0);
ok ($rdn && $rdn->getAttributeValue ('x'), ' ');

# Tests 19-20: escaped space
$dn = X500::DN->ParseRFC2253 ('x = \\ ');
ok ($dn && $dn->getRDNs(), 1);
$rdn = $dn && $dn->getRDN (0);
ok ($rdn && $rdn->getAttributeValue ('x'), ' ');

# Tests 21-22: quoted space
$dn = X500::DN->ParseRFC2253 ('x=" "');
ok ($dn && $dn->getRDNs(), 1);
$rdn = $dn && $dn->getRDN (0);
ok ($rdn && $rdn->getAttributeValue ('x'), ' ');

# Tests 21-22: quoted space
$dn = X500::DN->ParseRFC2253 ('x = " "');
ok ($dn && $dn->getRDNs(), 1);
$rdn = $dn && $dn->getRDN (0);
ok ($rdn && $rdn->getAttributeValue ('x'), ' ');

# Tests 25-27: more quoted spaces
$dn = X500::DN->ParseRFC2253 ('x=\\ \\ ');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), '  ');
$dn = X500::DN->ParseRFC2253 ('x=\\ \\ \\ ');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), '   ');
$dn = X500::DN->ParseRFC2253 ('x=\\  \\ ');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), '   ');

# Tests 28-29: commas with values
$dn = X500::DN->ParseRFC2253 ('x="a,b,c"');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), 'a,b,c');
$dn = X500::DN->ParseRFC2253 ('x=d\\,e');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), 'd,e');

# Test 30: escaped #, quote and a char in hex notation
$dn = X500::DN->ParseRFC2253 ('x=\\#\"\\41');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), '#"A');

# Test 31-32: bytes in hex notation
$dn = X500::DN->ParseRFC2253 ('x=#616263');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), 'abc');
$dn = X500::DN->ParseRFC2253 ('x=#001AFF');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), "\0\x1a\xff");

# Test 33: more special characters
$dn = X500::DN->ParseRFC2253 ('x=",=+<>#;"');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('x'), ',=+<>#;');

# Test 34: UTF-8 example from RFC 2253
$dn = X500::DN->ParseRFC2253 ('SN=Lu\C4\8Di\C4\87');
ok ($dn && $dn->getRDN (0)->getAttributeValue ('SN'), 'Lučić');

# Tests 35-39: multi-valued RDN
$dn = X500::DN->ParseRFC2253 ('foo=1 + bar=2, baz=3');
ok ($dn && $dn->hasMultivaluedRDNs, 1);
ok ($dn && $dn->getRDNs(), 2, 1);
$rdn = $dn && $dn->getRDN (1);
ok ($rdn && $rdn->getAttributeTypes(), 2);
ok ($rdn && $rdn->getAttributeValue ('foo'), '1');
ok ($rdn && $rdn->getAttributeValue ('bar'), '2');

# Test 40: illegal RFC 2253 syntax
$dn = X500::DN->ParseRFC2253 ('foo');
ok ($dn, undef);

# Test 41: openssl formatted DN
$dn = eval { X500::DN->ParseOpenSSL ('/C=DE/CN=Test') };
ok (sub { !$dn && $@ }, qr:^use 'openssl -nameopt RFC2253' and ParseRFC2253():);

# Test 42: no openssl output for multi-valued RDN
$dn = new X500::DN (new X500::RDN ('foo'=>1, 'bar'=>2));
$s = eval { $dn->getOpenSSLString() };
ok (sub { $dn && !defined ($s) && $@ }, qr/^openssl syntax for multi-valued RDNs is unknown/);

# Test 43: produce openssl format with escapes
$dn = new X500::DN (new X500::RDN ('foo'=>'bar/\\baz'));
ok ($dn && $dn->getOpenSSLString(), '/foo=bar\\/\\\\baz');
