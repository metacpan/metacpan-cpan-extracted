#!perl -T

use Test::More tests => 16;

use XML::Snap;
use Data::Dumper;

$xml = XML::Snap->parse (<<'EOF');
<test id="0">
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
   <other id="8"/>
</test>
EOF

@list0 = $xml->elements ();
is (@list0, 4);

@list0 = $xml->elements ('element');
is (@list0, 3);
is ($list0[0]->get('id'), 1);
is ($list0[1]->get('id'), 4);
is ($list0[2]->get('id'), 5);

@list1 = $xml->all ('element');
is (@list1, 4);
@list2 = $xml->all ('element2');
is (@list2, 2);
is ($list2[0]->get('id'), 3);
is ($list2[1]->get('id'), 6);

$node = $xml->first (undef, 'id', 3);
isa_ok ($node, 'XML::Snap');
ok ($node->is('element2'));

@list3 = $xml->all (undef, 'attribute', 'aaa');

is (@list3, 2);
is ($list3[0]->get('id'), 4);
is ($list3[1]->get('id'), 7);

@list4 = $xml->all ('element', 'attribute', 'aaa');
is (@list4, 1);
is ($list4[0]->get('id'), 4);


