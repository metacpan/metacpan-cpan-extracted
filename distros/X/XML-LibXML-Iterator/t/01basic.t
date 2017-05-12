use Test;

BEGIN { plan tests => 1; }
END { if ($loaded) { ok(1);} }

use XML::LibXML::Iterator;
use XML::LibXML::NodeList::Iterator;

$loaded = 1;


