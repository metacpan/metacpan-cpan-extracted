#!perl -T

use Test::More tests => 8;

use XML::Snap;
use Data::Dumper;

$xml = XML::Snap->parse (<<'EOF');
<test id="0">
   <element id="1">test&amp;uuml;</element>
   <element id="2">test&amp;&lt;thing/&gt;</element>
</test>
EOF

is ($xml->loc('element[2]')->string, '<element id="2">test&amp;&lt;thing/&gt;</element>');
is ($xml->loc('element[2]')->rawstring, '<element id="2">test&<thing/></element>');
is ($xml->loc('element[2]')->content, 'test&amp;&lt;thing/&gt;');
is ($xml->loc('element[2]')->rawcontent, 'test&<thing/>');

$xml->bless_text;

is ($xml->loc('element[2]')->string, '<element id="2">test&amp;&lt;thing/&gt;</element>');
is ($xml->loc('element[2]')->rawstring, '<element id="2">test&<thing/></element>');
is ($xml->loc('element[2]')->content, 'test&amp;&lt;thing/&gt;');
is ($xml->loc('element[2]')->rawcontent, 'test&<thing/>');
