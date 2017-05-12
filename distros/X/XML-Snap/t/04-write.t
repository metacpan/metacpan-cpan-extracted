#!perl -T

use Test::More tests => 6;

use XML::Snap;

$xml = XML::Snap->parse (<<'EOF');
<test>
   <element id="1">
      <element id="2"/>
      <element2 id="3"/>
   </element>
   <element id="4" attribute="aaa"/>
   <element id="5">
      <element2 id="6">
         <element3 id="7" attribute="aaa"/>
      </element2>
   </element>
   <other/>
</test>
EOF

$xml->write ('test.xml');
$xml2 = XML::Snap->load ('test.xml');
isa_ok ($xml2, 'XML::Snap');
@list0 = $xml->elements ('element');
is (@list0, 3);
is ($list0[1]->get('id'), 4);
unlink 'test.xml';


# 2014-05-27 - check writing of blessed text (which didn't work this morning, sigh, it's always when I'm in the middle of an actual job that I find these things)
$xml->bless_text;
$xml->write ('test.xml');
$xml2 = XML::Snap->load ('test.xml');
isa_ok ($xml2, 'XML::Snap');
@list0 = $xml->elements ('element');
is (@list0, 3);
is ($list0[1]->get('id'), 4);
unlink 'test.xml';



#$xml->write_UCS2LE ('test.xml');
#$xml2 = XML::Snap->load ('test.xml');
#isa_ok ($xml2, 'XML::Snap');
#@list0 = $xml->elements ('element');
#is (@list0, 3);
#is ($list0[1]->get('id'), 4);
#unlink 'test.xml';
