
use strict;
use Test;
BEGIN { plan tests => 11 };

use X500::RDN;
ok(1); # If we made it this far, we're ok.

my $s;
my $rdn;

### Tests for X500::RDN follow

# Tests 2-5: check a single-valued RDN
$rdn = new X500::RDN ('c'=>'DE');
ok (ref $rdn, 'X500::RDN');
ok ($rdn && $rdn->isMultivalued, '');
ok ($rdn && $rdn->getRFC2253String, 'c=DE');
ok ($rdn && $rdn->getX500String, 'c=DE');

# Tests 6-11: multi-valued RDN example from RFC 2253
$rdn = new X500::RDN ('OU'=>'Sales', 'CN'=>'J. Smith');
ok (ref $rdn, 'X500::RDN');
ok ($rdn && $rdn->isMultivalued, 1);
ok ($rdn && $rdn->getAttributeValue ('OU'), 'Sales');
ok ($rdn && $rdn->getAttributeValue ('CN'), 'J. Smith');
$s = $rdn && $rdn->getRFC2253String;
ok (sub { $s eq 'OU=Sales+CN=J. Smith' || $s eq 'CN=J. Smith+OU=Sales'}, 1);
$s = $rdn && $rdn->getX500String;
ok (sub { $s eq '(OU=Sales, CN=J. Smith)' || $s eq '(CN=J. Smith, OU=Sales)'}, 1);

