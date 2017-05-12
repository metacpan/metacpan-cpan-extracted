#!perl -T

use Test::More;

BEGIN { use_ok('XML::FromArrayref', 'XML', ':PROLOG'); }

is( XMLdecl(), '<?xml version="1.0"?>', 'prints a default XML declaration' );

is( XMLdecl('1.1'), '<?xml version="1.1"?>', 'can set version of XML declaration' );

is(
    XMLdecl('1.2', 'CP-1252'),
    '<?xml version="1.2" encoding="CP-1252"?>',
    'can set version and encoding of XML declaration'
);

is( doctype('html'), '<!DOCTYPE html>', 'prints minimal HTML5 doctype' );

is(
    doctype('transaction', 'http://example.com/transaction.dtd'),
    '<!DOCTYPE transaction SYSTEM "http://example.com/transaction.dtd">',
    'prints private doctype with SYSTEM URI'
);

is(
    doctype('HTML', 'http://www.w3.org/TR/html4/strict.dtd', '-//W3C//DTD HTML 4.01//EN'),
    '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
    'prints HTML4.01 doctype with PUBLIC ID and URI'
);

is(
    doctype('transaction', undef, undef, '<!ELEMENT description (#PCDATA)>' ),
    '<!DOCTYPE transaction [ <!ELEMENT description (#PCDATA)> ]>',
    'prints doctype with internal subset'
);

done_testing();
