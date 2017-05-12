use Test;
BEGIN { plan tests => 16 }
use XML::Handler::HTMLWriter;
use XML::SAX;

my $output;
my $writer = XML::Handler::HTMLWriter->new(Output => \$output);
ok($writer);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
ok($parser);

$parser->parse(Source => { SystemId => "testfiles/empty_tags.xml" });

print $output, "\n";

ok($output);

ok($output, qr/<area>(?!<\/area>)/);
ok($output, qr(<base href=(["'])foo\1>(?!</base>)));
ok($output, qr(<basefont>(?!</basefont>)));
ok($output, qr(<br class=(["'])short\1>(?!</br>)));
ok($output, qr(<col>(?!</col>)));
ok($output, qr(<frame src=(["'])here\1>(?!</frame>)));
ok($output, qr(<hr class=(["'])long\1>(?!</hr>)));
ok($output, qr(<img src=(["'])there\1>(?!</img>)));
ok($output, qr(<input type=(["'])text\1>(?!</input>)));
ok($output, qr(<isindex>(?!</isindex>)));
ok($output, qr(<link type=(["'])text/css\1>(?!</link>)));
ok($output, qr(<param>(?!</param>)));
ok($output, qr/<meta .*?>(?!<\/meta>)/);

