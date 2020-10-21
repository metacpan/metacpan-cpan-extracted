use strict;
use warnings;

use Test::More;

use vars qw/ $loaded /;

BEGIN { plan tests => 1; }

END
{
    # TEST
    if ($loaded) { ok(1); }
}

use XML::LibXML::Iterator           ();
use XML::LibXML::NodeList::Iterator ();

$loaded = 1;

