#!perl -T

use Test::More tests => 22;

use XML::Snap;

$xml = XML::Snap->parse ('<test2><this><this2/><this3/></this></test2>');
isa_ok ($xml, 'XML::Snap');

$p1 = $xml->parent;
ok (not defined $p1);

$first_not_found = $xml->first ("not_found_thing");
ok (not defined $first_not_found);

$this3 = $xml->first ('this3');
ok (defined $this3);
isa_ok ($this3, 'XML::Snap');
is ($this3->name, 'this3');

$p = $this3->parent;
is ($p->name, 'this');

$a = $this3->ancestor('test2');
is ($a->name, 'test2');
is ($a, $xml);

$a2 = $this3->ancestor;
is ($a2->name, 'test2');
is ($a2, $xml);

$a3 = $this3->ancestor('notthere');
ok (not defined $a3);

$a4 = $this3->ancestor('this');
is ($a4->name, 'this');
is ($a4, $p);

$a5 = $this3->root;
is ($a5, $xml);

$this2 = $xml->first ('this2');
$this2->detach;
is ($this2->parent, undef);
is ($this2->string, "<this2/>");
is ($xml->string, '<test2><this><this3/></this></test2>');

$this = $xml->first ('this');
$this->replacecontent (XML::Snap->new('hi'), XML::Snap->new('there'));
is ($xml->string, '<test2><this><hi/><there/></this></test2>');

$source = XML::Snap->parse ('<source><another/><test/></source>');
$this->replacecontent_from ($source);
is ($xml->string, '<test2><this><another/><test/></this></test2>');

$another = $xml->first ('another');
$another->replace (XML::Snap->new('hi'), XML::Snap->new('there'));
is ($xml->string, '<test2><this><hi/><there/><test/></this></test2>');

$this->replace(XML::Snap->new('that'));
is ($xml->string, '<test2><that/></test2>');
