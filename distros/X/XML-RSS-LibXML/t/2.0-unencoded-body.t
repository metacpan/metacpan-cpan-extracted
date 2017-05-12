use strict;
use Test::More tests => 5;
use XML::RSS::LibXML;

isa_ok my $xml = XML::RSS::LibXML->new, 'XML::RSS::LibXML';

ok $xml->parsefile('t/data/2.0/unencoded-body.rss'), 'Parse feed file';

ok my $item = $xml->{items}[0], 'Get item';

is $item->{description},
    '<img src="http://whatever.net/foo.jpg"/><br/> This is the description',
    'Description should have HTML';
is $item->{content}{encoded},
    '<img src="http://whatever.net/foo.jpg"/><br/> This is the content',
    'Content should have HTML';
