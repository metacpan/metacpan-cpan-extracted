#!perl -T

use Test::More tests => 10;

use XML::Snap;
use Data::Dumper;

$xml = XML::Snap->parse (<<'EOF');
<test id="0">
   <element id="1">
      <element id="2"/>
      <element2 id="3"/>
   </element>
   <element id="1" location="second"/>
   <test location="test"/>
   <test location="other test"/>
   <element id="4" attribute="aaa"/>
   <element id="5">
      <element2 id="6">
         <element3 id="7" attribute="aaa"/>
      </element2>
   </element>
   <other id="8"/>
</test>
EOF

$t1 = $xml->loc('element[4]');
is($t1->string, '<element id="4" attribute="aaa"/>');
$t1 = $xml->loc('element(1)');
is($t1->string, '<element id="1" location="second"/>');
$t1 = $xml->loc('element[1].element[3]');
is($t1, undef); # Oops.
$t1 = $xml->loc('element[1].element2');
is($t1->string, '<element2 id="3"/>');
$t1 = $xml->loc('element[1].element2[3]');
is($t1->string, '<element2 id="3"/>');
$t1 = $xml->loc('element(2)');
is($t1->string, '<element id="4" attribute="aaa"/>');
$t1 = $xml->loc('test');
is($t1->string, '<test location="test"/>');

$e3 = $xml->first('element3');
is($e3->getloc, 'element[5].element2[6].element3[7]');
$e3 = $xml->first(undef, 'location', 'other test');
is($e3->getloc, 'test(1)');
$e3 = $xml->first('test');
is($e3->getloc, 'test');


