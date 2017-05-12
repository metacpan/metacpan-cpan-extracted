#!perl -T

use Test::More tests => 36;

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

$w = $xml->walk;
is ($w->()->name, 'test');
ok (not ref $w->()); # whitespace
is ($w->()->get('id'), '1');
ok (not ref $w->()); # whitespace
is ($w->()->get('id'), '2');
ok (not ref $w->()); # whitespace
is ($w->()->get('id'), '3');
ok (not ref $w->()); # whitespace
ok (not ref $w->()); # whitespace - there are two pieces of whitespace there, one inside element 1 and one outside!
is ($w->()->get('id'), '4');

$w = $xml->walk(sub {              # Skip the text pieces.
   return undef unless ref $_[0];
   $_[0];
});
is ($w->()->name, 'test');
is ($w->()->get('id'), '1');
is ($w->()->get('id'), '2');
is ($w->()->get('id'), '3');
is ($w->()->get('id'), '4');

$w = $xml->walk(sub {              # Return just ID values.
   return undef unless ref $_[0];
   return undef unless $_[0]->get('id');
   $_[0]->get('id');
});

is ($w->(), '1');
is ($w->(), '2');
is ($w->(), '3');
is ($w->(), '4');

$w = $xml->walk(sub {              # Skip text, prune ID=1, return elements.
   return undef unless ref $_[0];
   return (undef, 'prune') if $_[0]->get('id', '') == 1;
   $_[0];
});

is ($w->()->name, 'test');
is ($w->()->get('id'), '4');
is ($w->()->get('id'), '5');
is ($w->()->get('id'), '6');
is ($w->()->get('id'), '7');

$w = $xml->walk(sub {              # Skip text, prune ID=1 but still return it, return elements.
   return undef unless ref $_[0];
   return ($_[0], 'prune') if $_[0]->get('id', '') == 1;
   $_[0];
});

is ($w->()->name, 'test');
is ($w->()->get('id'), '1');
is ($w->()->get('id'), '4');
is ($w->()->get('id'), '5');
is ($w->()->get('id'), '6');
is ($w->()->get('id'), '7');


$w = $xml->walk_elem(sub {              # Do the same but without needing to explicitly skip text.
   return ($_[0], 'prune') if $_[0]->get('id', '') == 1;
   $_[0];
});

is ($w->()->name, 'test');
is ($w->()->get('id'), '1');
is ($w->()->get('id'), '4');
is ($w->()->get('id'), '5');
is ($w->()->get('id'), '6');
is ($w->()->get('id'), '7');

