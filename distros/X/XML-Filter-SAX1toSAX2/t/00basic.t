use Test;
BEGIN { plan tests => 3 }
END { ok($loaded_1); ok($loaded_2); }
require XML::Filter::SAX1toSAX2;
$loaded_1++;
require XML::Filter::SAX2toSAX1;
$loaded_2++;
ok(1);
