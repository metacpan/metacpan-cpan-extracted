use Test;
BEGIN { plan tests => 2 }
END { ok($loaded) }
use XML::Generator::Win32OLETypeLib;
$loaded++;
ok(1);
