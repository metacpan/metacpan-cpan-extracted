#!perl -T

use Test::More tests=>35;
use XML::Snap;
use Data::Dumper;

my $text = <<'EOF';
<test>
This is a rather typical example of the use of XML
for <i>formatted text</i> instead of as a
<i>structured data format</i>.
</test>
EOF

$xml = XML::Snap->parse ($text);

@list0 = $xml->children ();
is (@list0, 5);
@list1 = $xml->elements ();
is (@list1, 2);

is (ref($list0[0]), '');

is ($xml->string . "\n", $text);

$xml2 = XML::Snap->parse_with_refs ($text);

@list0 = $xml2->children ();
is (@list0, 5);
@list1 = $xml2->elements ();
is (@list1, 2);

is (ref($list0[0]), 'XML::Snap');
ok ($list0[0]->istext);
ok (not $list0[1]->istext);
$exp_text = "\nThis is a rather typical example of the use of XML\nfor ";
is ($list0[0]->gettext, $exp_text);
is ($list0[0]->name, '');
ok (not $list0[0]->is('tag'));
is ($list0[0]->parent, undef);
is ($list0[0]->children, ());
is ($list0[0]->string, $exp_text);
is ($list0[0]->rawstring, $exp_text);
is ($list0[0]->content, $exp_text);
is ($list0[0]->rawcontent, $exp_text);

is ($xml2->string . "\n", $text);

$xml->bless_text;
@list0 = $xml->children ();
is (@list0, 5);

is (ref($list0[0]), 'XML::Snap');
ok ($list0[0]->istext);
ok (not $list0[1]->istext);
is ($list0[0]->gettext, "\nThis is a rather typical example of the use of XML\nfor ");

$xml->bless_text;
@list0 = $xml->children ();
is (@list0, 5);

is (ref($list0[0]), 'XML::Snap');
ok ($list0[0]->istext);
ok (not $list0[1]->istext);
is ($list0[0]->gettext, "\nThis is a rather typical example of the use of XML\nfor ");

$xml->unbless_text;
@list0 = $xml->children ();
is (@list0, 5);
@list1 = $xml->elements ();
is (@list1, 2);
is (ref($list0[0]), '');

$xml->unbless_text;
@list0 = $xml->children ();
is (@list0, 5);
@list1 = $xml->elements ();
is (@list1, 2);
is (ref($list0[0]), '');


#diag Dumper($xml2);

