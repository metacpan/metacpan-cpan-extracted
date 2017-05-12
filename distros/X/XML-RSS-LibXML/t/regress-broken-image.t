use strict;
use Test::More;

BEGIN {
    eval {
        require Test::Exception;
        require Test::Warn;

        Test::Exception->import();
        Test::Warn->import;
    };

    if ($@) {
        plan (skip_all => "This test require Test::Exception and Test::Warn");
    } else {
        plan (tests => 2);
    }
}

use XML::RSS::LibXML;

my $xml =<<EOXML;
<?xml version="1.0"?>
<rss version="2.0">
<channel>
  <title>Broken RSS</title>
  <image>http://whatever.com/foo.gif</image>
</channel>
</rss>
EOXML

{
    my $rss = XML::RSS::LibXML->new;
    lives_ok { 
        $rss->parse($xml)
    } 'parse generates warning';

    ok( ! $rss->{item}->[0]->{image} );
}
