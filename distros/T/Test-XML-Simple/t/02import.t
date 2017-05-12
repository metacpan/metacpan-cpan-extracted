use Test::More tests => 5;
use Test::XML::Simple;

ok(defined \&xml_valid, "xml_valid imported");
ok(defined \&xml_node, "xml_node imported");
ok(defined \&xml_is, "xml_is imported");
ok(defined \&xml_is_deeply, "xml_is_deeply imported");
ok(defined \&xml_like, "xml_like imported");
