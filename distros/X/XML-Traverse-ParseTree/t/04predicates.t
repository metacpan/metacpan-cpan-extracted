
use lib ("..",".","blib/lib","../blib/lib");
use XML::Traverse::ParseTree;
use XML::Parser;
use Data::Dumper;

#use Test::More qw(no_plan);
use Test::More tests => 21;

$xml = <<'_XML_';
<?xml version="1.0" encoding="iso-8859-1"?>
<main>
  <sub1 id="1">
    <sub2 id="2">two</sub2>
    <sub2 id="3">three</sub2>
  </sub1>
  <sub1 id="4">
    <sub2 id="5">five</sub2>
    <sub2 id="6">six</sub2>
  </sub1>
</main>
_XML_

my $p = XML::Parser->new(Style => "Tree");
my $r = $p->parse($xml);
my $h = XML::Traverse::ParseTree->new();

# print Dumper($r);

*id = $h->getter('@id');

my $i = $h->get($r,"//sub2");

is(id($i->()),"2");
is(id($i->()),"3");
is(id($i->()),"5");
is(id($i->()),"6");

$i = $h->get($r,'sub1','sub2[*]');
is(id($i->()),"2");
is(id($i->()),"3");

$i = $h->get($r,'sub1[2]','sub2[*]');
is(id($i->()),"5");
is(id($i->()),"6");

$e = $h->get($r,'sub1[2]','sub2[2]');
is(id($e),"6");

$i = $h->get($r,"sub1[*]","sub2[*]");

is(id($i->()),"2");
is(id($i->()),"3");
is(id($i->()),"5");
is(id($i->()),"6");

$i = $h->get($r,"sub1[*]","sub2[*]","#TEXT");

is($i->(),"two");
is($i->(),"three");
is($i->(),"five");
is($i->(),"six");

$i = $h->get($r,"sub1[*]","sub2[*]",'@id');

is($i->(),"2");
is($i->(),"3");
is($i->(),"5");
is($i->(),"6");


1;
