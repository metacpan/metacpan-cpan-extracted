use strict;
use warnings;

use Test::More qw/no_plan/;

use YAX::Parser;

our $xstr = <<XML;
<rootnode id="root">
<tag1 id="1">text node 1 <!--comment node--> text node 2</tag1>
<tag1 id="2"><?piTarget piData ?>foo2</tag1>
<tag1 id="3">foo3</tag1>
<tag1 id="4">foo4
  <tag>
    <a pin="1"><b>b1 text</b></a>
    <a pin="2"><b>b2 text</b></a>
    <a pin1="3">
      <b>
        <tag>no attribute</tag>
        <tag tid="red">Red-Taggy</tag>
        <tag tid="green">Green-Taggy</tag>
        <tag id1="1" id2="2">Multi-Taggy</tag>
      </b>
    </a>
  </tag>
</tag1>
</rootnode>
XML

my $xdoc = YAX::Parser->parse( $xstr );
my $list = $xdoc->query('..b');
is( scalar( @$list ), 3, 'got 3 elements' );
for ( 0 .. 2 ) {
    is($list->[$_]->name, 'b', "element $_ is a <b> tag" );
}

$list = $xdoc->query('..tag1');
is( scalar( @$list ), 4, 'got 4 elements' );
for ( 0 .. 3 ) {
    is( $list->[$_]->name, 'tag1', "element $_ is a <tag1> tag" );
    is( $list->[$_]->{id}, $_+1, "element $_ has id ".($_+1) );
}

$list = $xdoc->query('.rootnode.tag1');
is( scalar( @$list ), 4, 'got 4 elements' );
for ( 0 .. 3 ) {
    is( $list->[$_]->name, 'tag1', "element $_ is a <tag1> tag" );
    is( $list->[$_]->{id}, $_+1, "element $_ has id ".($_+1) );
}

$list = $xdoc->query('..tag1.tag.a');
is( scalar( @$list ), 3, 'got 3 elements' );
for ( 0 .. 2 ) {
    is( $list->[$_]->name, 'a', "element $_ is a <a> tag" );
}

$list = $xdoc->query('..tag1[0]');
is( scalar( @$list ), 1, 'got 1 element');
is( $list->[0]->{id}, "1", 'id is "1"' );

$list = $xdoc->query('..tag1[-1]');
is( scalar( @$list ), 1, 'got 1 element');
is( $list->[0]->{id}, "4", 'id is "4"' );

$list = $xdoc->query('..tag1[1]');
is( scalar( @$list ), 1, 'got 1 element');
is( $list->[0]->{id}, "2", 'id is "2"' );

$list = $xdoc->query('..tag1[0..1]');
is( scalar( @$list ), 2, 'got 2 elements');
is( $list->[0]->{id}, "1", 'id is "1"' );
is( $list->[1]->{id}, "2", 'id is "2"' );

$list = $xdoc->query('..tag1[0].#text');
is( scalar( @$list ), 2, 'got 2 nodes' );
is( $list->[0]->type, 3, '1 is a text node' );
is( $list->[1]->type, 3, '2 is a text node' );
is( $list->[0]->data, 'text node 1 ', '1 has the right text' );
is( $list->[1]->data, ' text node 2', '2 has the right text' );

$list = $xdoc->query('..tag1.tag.a.b.#node');
is( scalar( @$list ), 11, 'got 11 nodes' );

$list = $xdoc->root->query('.@*');
is( scalar( @$list ), 1, 'got 1 attribute' );
is( $list->[0]->{id}, 'root', 'attribute value is sane' );

$list = $xdoc->query('..tag1.(@id eq "2")');
is( scalar( @$list ), 1, 'got 1 element' );
is( $list->[0]->{id}, '2', '@id is sane' );

$list = $xdoc->query('..tag1.(@id != 3)[2]..a');
is( scalar( @$list ), 3, 'got 3 elements' );
is( $list->[0]->name, 'a', 'tagname is a' );
is( $list->[1]->name, 'a', 'tagname is a' );
is( $list->[2]->name, 'a', 'tagname is a' );

$list = $xdoc->query('..tag1.(@id != 3)[2]..a.parent()');
is( scalar( @$list ), 3, 'got 3 elements' );
is( $list->[0]->name, 'tag', 'tagname is tag' );

