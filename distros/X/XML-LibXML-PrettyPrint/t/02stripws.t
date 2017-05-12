use strict;
use warnings;
use Test::More;
use Test::Warnings;

use XML::LibXML;
use XML::LibXML::PrettyPrint;

sub strip 
{
	my $xml = XML::LibXML->new->parse_string(shift);
	XML::LibXML::PrettyPrint->new(@_)->strip_whitespace($xml);
	return $xml->documentElement->toString;
}

is(strip('<foo>   <bar></bar>   </foo>'),
	'<foo><bar/></foo>',
	'simple test');

is(strip("<foo>   <bar>\t</bar>   </foo>"),
	'<foo><bar/></foo>',
	'fully collapsed');

is(strip("<foo>a <bar>b</bar> c</foo>"),
	'<foo>a<bar>b</bar>c</foo>',
	'with text');

my $pp = XML::LibXML::PrettyPrint->new(element=>{inline=>['bar']});
is($pp->element_category(XML::LibXML::Element->new('foo')),
	XML::LibXML::PrettyPrint->EL_BLOCK,
	"block elements recognised");
is($pp->element_category(XML::LibXML::Element->new('bar')),
	XML::LibXML::PrettyPrint->EL_INLINE,
	"inline elements recognised");

is(strip("<foo>a <bar>b</bar>c</foo>", element => {inline=>['bar']}),
	'<foo>a <bar>b</bar>c</foo>',
	'if next sibling is an inline element, preserves trailing space');

is(strip("<foo>a<bar>b</bar> c</foo>", element => {inline=>['bar']}),
	'<foo>a<bar>b</bar> c</foo>',
	'if prev sibling is an inline element, preserves leading space');
	
is(strip("<foo>a<bar>b</bar>c</foo>", element => {inline=>['bar']}),
	'<foo>a<bar>b</bar>c</foo>',
	'inline elements do not introduce space');

is(strip("<foo>a\t<bar>b</bar>\nc</foo>", element => {inline=>['bar']}),
	'<foo>a <bar>b</bar> c</foo>',
	'inline elements normalise space');

is(strip("<foo>a<bar>b  </bar> c</foo>", element => {inline=>['bar']}),
	'<foo>a<bar>b </bar> c</foo>',
	'space inside inline elements is normalised');

is(strip("<foo>a    b</foo>"),
	'<foo>a b</foo>',
	'multiple spaces collapsed');

is(strip("<foo>a\t\t\tb</foo>"),
	'<foo>a b</foo>',
	'multiple tabs collapsed to a space');

is(strip("<foo>a\n\n\nb</foo>"),
	'<foo>a b</foo>',
	'multiple new lines collapsed to space');

is(strip("<pre>   foo   </pre>", elements => {preserves_whitespace=>['pre']}),
	"<pre>   foo   </pre>",
	'can preserve whitespace');

is(strip("<pre>   foo  <b> bold</b>  <i>italic  \t</i>   </pre>", elements => {preserves_whitespace=>['pre']}),
	"<pre>   foo  <b> bold</b>  <i>italic  \t</i>   </pre>",
	'can preserve whitespace into descendents');

is(strip("<foo>  <!-- comment -->  </foo>"),
	'<foo><!-- comment --></foo>',
	'with a comment');
	
done_testing;
