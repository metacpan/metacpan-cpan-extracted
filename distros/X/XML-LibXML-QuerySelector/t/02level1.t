use Test::More tests => 7;
use XML::LibXML::QuerySelector;

my $document = XML::LibXML->new->parse_string(<<'XHTML');
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Selectors API Example</title>
  </head>
  <body>
    <div id="foo">
      <p class="warning">This is a sample warning</p>
      <p class="error">This is a sample error</p>
    </div>
    <div id="bar">
      <p>...</p>
    </div>
  </body>
</html>
XHTML

isa_ok($document, 'XML::LibXML::QuerySelector');

my $alerts = $document->querySelectorAll("p.warning, p.error");
is $alerts->size, 2, 'returns correct number of alerts';
is $alerts->shift->toString, '<p class="warning">This is a sample warning</p>';
is $alerts->shift->toString, '<p class="error">This is a sample error</p>';

my $x = $document->querySelector("#foo, #bar");
my $y = $document->querySelector("#bar, #foo");
is $x->toString, $y->toString;

my $div = $document->querySelector("#bar");
my $p   = $div->querySelector("body p");
ok defined $p;
is $p->toString, '<p>...</p>';