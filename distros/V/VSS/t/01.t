use Test::Simple tests => 3;

require Win32::TieRegistry;
require Win32::OLE;

ok(1);

use VSS;

ok(2);

ok(VSS->new());