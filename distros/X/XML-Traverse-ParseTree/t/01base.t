
use lib ("..",".","blib/lib","../blib/lib");
use XML::Traverse::ParseTree;
use XML::Parser;
# use Data::Dumper;

#use Test::More qw(no_plan);;
use Test::More tests => 13;

$xml = <<'_XML_';
<?xml version="1.0" encoding="iso-8859-1"?>
<main>
  <sub1>
    <sub1sub1 a="bla">text</sub1sub1>
    <sub1sub2/>
  </sub1>
  <sub2>Hallo</sub2>
</main>
_XML_

my $p = XML::Parser->new(Style => "Tree");
my $r = $p->parse($xml);
my $h = XML::Traverse::ParseTree->new();

# print Dumper($r);

## internal routines
my @a = $h->_action('abc');
is_deeply(\@a,['#CHILD','abc',1,'SCALAR']);
@a = $h->_action('abc[*]');
is_deeply(\@a,['#CHILD','abc',undef,'ITERATOR']);
@a = $h->_action('abc[2]');
is_deeply(\@a,['#CHILD','abc',2,'SCALAR']);

## public

is($h->get_element_name($r),"main","getElementName");

my $i = $h->child_iterator($r);

$e1 = $i->();
$e2 = $i->();

is($h->get_element_name($e1),"sub1");
is($h->get_element_name($e2),"sub2");

my $ii = $h->child_iterator($e1);

$ee1 = $ii->();
$ee2 = $ii->();

is($h->get_element_name($ee1),"sub1sub1");
is($h->get_element_name($ee2),"sub1sub2");

is_deeply($h->get_element_attrs($ee1),{ a => "bla" });

is($h->get_element_text($ee1),"text");

is_deeply($h->element_to_object($ee1), { _name => "sub1sub1", _attr => { a => "bla" }, _text => "text" });

is($h->get($r,"sub1","sub1sub1",'@a'),"bla");
is($h->get($r,"sub1","sub1sub1","#TEXT"),"text");

1;
