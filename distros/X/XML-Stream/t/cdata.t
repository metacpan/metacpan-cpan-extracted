use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok('XML::Stream', 'Node'); }

my $x = XML::Stream::Node->new;
isa_ok $x, 'XML::Stream::Node';
$x->set_tag("body");
$x->add_cdata("one");

is ($x->GetXML(), q[<body>one</body>], 'cdata');

my $y = $x->copy;
isa_ok $y, 'XML::Stream::Node';
isnt $x, $y, 'not the same';

is ($y->GetXML(), q[<body>one</body>], 'copy cdata');

$x->add_child("a","two")->put_attrib(href=>"http://www.google.com");
$x->add_cdata("three");

is ($x->GetXML(), q[<body>one<a href='http://www.google.com'>two</a>three</body>], 'cdata/element/cdata');

my $z = $x->copy;
isa_ok $z, 'XML::Stream::Node';
isnt $x, $z, 'not the same';
isnt $y, $z, 'not the same';

is ($z->GetXML(), q[<body>one<a href='http://www.google.com'>two</a>three</body>], 'copy cdata/element/cdata');

