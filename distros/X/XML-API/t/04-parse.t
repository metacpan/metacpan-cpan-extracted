use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Test::Memory::Cycle;

BEGIN {
    use_ok('XML::API');
}

is( XML::API::_escapeXML( '' ), '', 'escape null' );

is(
    XML::API::_escapeXML( '< > & "' ),
    '&lt; &gt; &amp; &quot;',
    'escape basic'
);

is( XML::API::_escapeXML( '&nbsp;' ), '&nbsp;', 'escape unknown entities' );

#is(XML::API::_escapeXML(
#    '<!-- a comment -->'
#),
#    '<!-- a comment -->',
#'no escape comment');

# make a root for our tree
my $x = XML::API->new;
isa_ok( $x, 'XML::API' );

$x->_parse('<div class="divclass"><p>text</p></div>');

is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<div class="divclass">
  <p>text</p>
</div>', 'parse'
);

$x->_parse_chunk('<one>1</one><two>2</two>');

is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<div class="divclass">
  <p>text</p>
</div>
<one>1</one>
<two>2</two>', 'parse chunk'
);

$x = XML::API->new;
$x->_parse_chunk('<one>&nbsp;</one>');
is(
    "$x", '<?xml version="1.0" encoding="UTF-8" ?>
<one>&nbsp;</one>', 'parse non-xml entity'
);

memory_cycle_ok( $x, 'memory cycle' );

is( XML::API::_escapeXML( " ' " ),
    " &apos; ", 'escape apostrophe/single quote' );
