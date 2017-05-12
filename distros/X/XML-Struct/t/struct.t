use strict;
use Test::More;

my $input = join "\n", '<?xml version="1.0" encoding="UTF-8"?>',
    '<root xmlns="http://example.org/">!<x>42</x></root>','';

use XML::Struct qw(readXML writeXML simpleXML removeXMLAttr);

my $xml = readXML( \$input );
is_deeply $xml, [ root => { xmlns => 'http://example.org/' }, [ '!', [x => {}, [42]] ] ];

my $doc = writeXML( $xml );
is_deeply $doc, $input;

my $simple = simpleXML( $xml, root => 'record' );
is_deeply $simple, { record => { xmlns => 'http://example.org/', x => 42 } };

my $xml2 = removeXMLAttr($xml);
is_deeply $xml2, [ root => [ '!', [ x => [42] ] ] ];

done_testing;
