
use strict;
use warnings;
use Test::More;

eval{ require Win32::API; };
$@ and plan skip_all => "Win32::API is required";

plan tests => 3;

use Win32::Codepage::Simple qw(get_codepage get_acp get_oemcp);

my ($cp, $acp, $ocp);

isnt($cp = get_codepage(), undef, 'get_codepage() returns valid value')
  and diag("codepage = $cp");
isnt($acp = get_acp(),      undef, 'get_acp() returns valid value')
  and diag("ansi codepage = $acp");
isnt($ocp = get_oemcp(),    undef, 'get_oemcp() returns valid value')
  and diag("oem codepage = $ocp");

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
