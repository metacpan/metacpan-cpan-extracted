#!perl -T

use Test::More;

BEGIN { use_ok('XML::FromArrayref', 'XML', ':TAGS'); }

is(
	XML( [ p => 'foo' ] ),
	'<p>foo</p>',
	'prints an XML element'
);

is(
	XML( [ p => { attrib => 'this&that' }, 'foo' ] ),
	'<p attrib="this&amp;that">foo</p>',
	'encodes attribute values'
);

is(
	XML( [ p => { attrib => undef }, 'foo' ] ),
	'<p>foo</p>',
	'skips attribute with undefined values'
);

is(
	XML( [ img => { src => 'image.png' } ], ['br'] ),
	'<img src="image.png"/><br/>',
	'prints empty XML elements as self-closing tags'
);

is(
	XML( [ p => [ b => 'bold' ], 'foo' ] ),
	'<p><b>bold</b>foo</p>',
	'prints nested XML elements'
);

is(
	XML( [ p => [ 0 && b => 'notbold' ], 'foo' ] ),
	'<p>notboldfoo</p>',
	'skips XML elements with false tag names'
);

is(
	XML( [ p => 'foo', [[ '<i>italics</i>' ]] ] ),
	'<p>foo<i>italics</i></p>',
	'leaves already-escaped text alone'
);

is(
	start_tag( p => { class => 'test-class' } ),
	'<p class="test-class">',
	'prints a start tag'
);

done_testing();
