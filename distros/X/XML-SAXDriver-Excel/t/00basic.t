use Test;

BEGIN { plan tests => 5 }
END { ok($loaded, 2) }

use XML::SAXDriver::Excel;

$loaded++;
ok(1);

require XML::Handler::YAWriter;  ## We do require so that the test does not load until run time
$loaded++;
ok(1);

my $writer = XML::Handler::YAWriter->new(AsString => 1);

my $parser = XML::SAXDriver::Excel->new(
    Source => {SystemId =>
	"Data1.xls" },
    Handler => $writer,
    );

if ($output = $parser->parse())
{
    ok(1)
}
my $parser2 = XML::SAXDriver::Excel->new(
    Source => {SystemId =>
	"Data1.xls" },
    Handler => $writer,
    Dynamic_Col_Headings => 1
    );
if ($output2 = $parser2->parse())
{
    ok(1)
}
open FILE, ">test.xml";
print FILE $output;
close FILE;
open FILE, ">test2.xml";
print FILE $output2;
close FILE;

    
    
    





