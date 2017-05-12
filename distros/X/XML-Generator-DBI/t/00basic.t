use Test;
BEGIN { plan tests => 2 }
END { ok($loaded) }
use XML::Generator::DBI;
$loaded++;
ok(1);
