#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use lib '../../lib';

use Test::More tests => 25;

# Todo: Looks funny right now:
#<?xml version="1.0"?>
#<!-- initially, the default namespace is "books" -->
#<book xmlns='urn:loc.gov:books' xmlns:isbn='urn:ISBN:0-395-36341-6'>
#  <title>Cheaper by the Dozen</title>
#  <isbn:number>1568491379</isbn:number>
#  <notes>
#    <!-- make HTML the default namespace for some commentary -->
#    <p xmlns='urn:w3-org-ns:HTML'>This is a <i>funny</i> book!</p>
#  </notes>
#</book>


my $pi = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';

use_ok('XML::Loy');

my $i = 1;

ok(my $xml = XML::Loy->new('test'), 'Constructor String');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test />
PP

ok($xml->add('Child'), 'Child added');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
</test>
PP

ok($xml->add('Child2' => {foo => 'bar' }), 'Child added');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
</test>
PP

ok($xml->add('Child3' => {foo => 'bar', bob => 'alice' }), 'Child added');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />
</test>
PP

ok($xml->add('Child4' => {foo => 'bar', bob => 'alice', mino => 'taurus' }), 'Child added');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
</test>
PP

ok(my $in = $xml->add('Child5' => 'Text'), 'Child added');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text</Child5>
</test>
PP

ok($xml->at('Child4')->comment('Comment1'), 'Comment on 4');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />

  <!-- Comment1 -->
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text</Child5>
</test>
PP

ok($xml->at('Child4')->comment('Comment2'), 'Comment on 4');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />

  <!-- Comment1
       Comment2 -->
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text</Child5>
</test>
PP

ok($xml->at('Child4')->comment('Comment3 -->'), 'Comment on 4');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />

  <!-- Comment1
       Comment2
       Comment3 --&gt; -->
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text</Child5>
</test>
PP

ok($in->add(GrandChild => 'Text2'), 'Grandchild sadded');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar" />
  <Child3 bob="alice"
          foo="bar" />

  <!-- Comment1
       Comment2
       Comment3 --&gt; -->
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text
    <GrandChild>Text2</GrandChild>
  </Child5>
</test>
PP

ok($xml->at('Child2')->add(GrandChild2 => {
  att => 'ribute',
  para => 'meter'
} => 'Text2' => 'Small comment'),
   'Grandchild added with comment and attributes');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar">

    <!-- Small comment -->
    <GrandChild2 att="ribute"
                 para="meter">Text2</GrandChild2>
  </Child2>
  <Child3 bob="alice"
          foo="bar" />

  <!-- Comment1
       Comment2
       Comment3 --&gt; -->
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text
    <GrandChild>Text2</GrandChild>
  </Child5>
</test>
PP

ok($xml->at('GrandChild2')->comment('And another one'), 'Add another comment');

is($xml->to_pretty_xml, <<'PP', 'Pretty Print');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<test>
  <Child />
  <Child2 foo="bar">

    <!-- Small comment
         And another one -->
    <GrandChild2 att="ribute"
                 para="meter">Text2</GrandChild2>
  </Child2>
  <Child3 bob="alice"
          foo="bar" />

  <!-- Comment1
       Comment2
       Comment3 --&gt; -->
  <Child4 bob="alice"
          foo="bar"
          mino="taurus" />
  <Child5>Text
    <GrandChild>Text2</GrandChild>
  </Child5>
</test>
PP
