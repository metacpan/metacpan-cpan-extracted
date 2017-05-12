use Test;

BEGIN { plan tests => 4 }
END { ok($loaded, 2) }

use XML::SAXDriver::CSV;  
$loaded++;
ok(1);

require XML::Handler::YAWriter;  ## We do require so that the test does not load until run time
$loaded++;
ok(1);

my $writer = XML::Handler::YAWriter->new(AsString => 1);
my $parser = XML::SAXDriver::CSV->new(
    Source => {SystemId =>
	"Data1.csv" },
    Handler => $writer,
    );

if ($parser->parse())
{
    ok(1);
}

    
    
    





