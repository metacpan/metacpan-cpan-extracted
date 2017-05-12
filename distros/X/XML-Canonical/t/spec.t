# tests for examples in w3 recommendation

use XML::Canonical;
use Test;

BEGIN {plan tests => 8};

for my $i (1..6) {
  my $input = slurp("t/in/3${i}_input.xml");
  my $canon_expect = slurp("t/in/3${i}_c14n.xml");
  chomp($canon_expect);
  my $canon = XML::Canonical->new(comments => 0);
  my $canon_output = $canon->canonicalize_string($input);
  ok($canon_output, $canon_expect);
}

my $input = slurp("t/in/31_input.xml");
my $canon_expect = slurp("t/in/31_c14n-comments.xml");
chomp($canon_expect);
my $canon = XML::Canonical->new(comments => 1);
my $canon_output = $canon->canonicalize_string($input);
ok($canon_expect, $canon_output);

$input = slurp("t/in/37_input.xml");
$canon_expect = slurp("t/in/37_c14n.xml");
chomp($canon_expect);
$canon = XML::Canonical->new(comments => 1);
my $doc = XML::GDOME->createDocFromString($input);
my $elem = $doc->createElement("foo");
$elem->setAttributeNS("http://www.w3.org/2000/xmlns/","xmlns:ietf","http://www.ietf.org");
my $nsresolv = $elem->xpath_createNSResolver;
my $res = $doc->xpath_evaluate(qq{
(//. | //@* | //namespace::*)
[
   self::ietf:e1 or (parent::ietf:e1 and not(self::text() or self::e2))
   or
   count(id("E3")|ancestor-or-self::node()) = count(ancestor-or-self::node())
]
}, $nsresolv);

$canon_output = $canon->canonicalize_document($doc, $res);
ok($canon_output, $canon_expect);

sub slurp {
  my ($filename) = @_;
  my $text;
  open F, "$filename";
  while(<F>){
    $text .= $_;
  }
  close F;
  chomp($text);
  return $text;
}
