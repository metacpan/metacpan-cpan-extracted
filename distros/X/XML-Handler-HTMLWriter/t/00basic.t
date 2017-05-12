use Test;
BEGIN { plan tests => 2 }
END { ok($loaded) }
use XML::Handler::HTMLWriter;
$loaded++;
ok(1);
