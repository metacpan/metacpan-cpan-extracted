package main;
use strict;
use warnings;

use Test::More tests => 1;

use XML::Hash::XS 'xml2hash';
$XML::Hash::XS::keep_root = 0;

{
    is
        xml2hash('<?xml-stylesheet href="default.css" title="Default style"?>' .
                 '<?xml-stylesheet alternate="yes" href="alt.css" title="Alternative style"?>' .
                 '<?xml-stylesheet href="single-col.css" media="all and (max-width: 30em)"?>' .
                 '<root>OK</root>'),
        "OK",
        'simple',
    ;
}
