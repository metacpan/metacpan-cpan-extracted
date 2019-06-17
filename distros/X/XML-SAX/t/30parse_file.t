use Test;
BEGIN { plan tests => 5 }
use XML::SAX::PurePerl;
use XML::SAX::PurePerl::DebugHandler;
use IO::File;

my $handler = XML::SAX::PurePerl::DebugHandler->new();
ok($handler);

my $parser = XML::SAX::PurePerl->new(Handler => $handler);
ok($parser);

my $file1 = IO::File->new("testfiles/01.xml");
ok($file1);

eval {
$parser->parse_file($file1);
};
print $@;
ok(!$@);

my $file2 = "testfiles/01.xml";

eval {
$parser->parse_file($file2);
};
print $@;
ok(!$@);

