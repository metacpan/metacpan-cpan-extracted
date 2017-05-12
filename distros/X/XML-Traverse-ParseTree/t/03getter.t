
use lib ("..",".","blib/lib","../blib/lib");
use XML::Traverse::ParseTree;
use XML::Parser;
use Data::Dumper;

#use Test::More qw(no_plan);;
use Test::More tests => 4;

$xml = <<'_XML_';
<?xml version="1.0" encoding="iso-8859-1"?>
<main>
  <sub1 id="1">
    <sub1 id="2">text</sub1>
  </sub1>
  <sub1 id="3">
<sub2>Hallo<sub1 id="4"/>ollaH</sub2>
</sub1>
<sub3>A text <b>with <i>some</i> more</b> <emp>markup</emp></sub3>
</main>
_XML_

my $p = XML::Parser->new(Style => "Tree");
my $r = $p->parse($xml);
my $h = XML::Traverse::ParseTree->new();

# print Dumper($r);

*id = $h->getter('@id');

my $i = $h->dfs_iterator($r,"sub1");

is(id($i->()),"1");
is(id($i->()),"2");
is(id($i->()),"3");
is(id($i->()),"4");

1;
