# vim: set ft=perl:
use lib './lib';

use Test::More qw(no_plan);

use XML::DOM::Lite::Parser;
use XML::DOM::Lite::Serializer;

my $xml = <<_;
<root>
 <thing1 attr1="foo1">Text Node</thing1>
 <thing2 attr1="bar1">Text Node</thing1>
 <empty />
 <thing3 attr1="baz1">
   <child1>Text Node</child1>
 </thing1>
</root>
_

my $parser = XML::DOM::Lite::Parser->new( whitespace => 'strip' );
my $doc = $parser->parse( $xml );
my $serializer = XML::DOM::Lite::Serializer->new;
my $out = $serializer->serializeToString( $doc );
my $cmp = qq{
<root>
  <thing1 attr1="foo1">
    Text Node
  </thing1>
  <thing2 attr1="bar1">
    Text Node
  </thing2>
  <empty />
  <thing3 attr1="baz1">
    <child1>
      Text Node
    </child1>
  </thing3>
</root>};

ok( $out eq $cmp );
