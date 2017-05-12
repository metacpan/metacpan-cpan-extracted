use strict;
use warnings;
use Test::More;
use Test::Warnings qw(warning);

use XML::LibXML;
use XML::LibXML::PrettyPrint;

sub indent
{
	my $xml = XML::LibXML->new->parse_string(shift);
	my $pp  = XML::LibXML::PrettyPrint->new(@_);
	$pp->strip_whitespace($xml);
	$pp->indent($xml);
	return $xml->documentElement->toString;
}

is(indent('<foo>   <bar />   </foo>'),
	"<foo>\n\t<bar/>\n</foo>",
	'simple test');

like(
	warning {
		is(indent('<foo>   <bar />   </foo>', indent_string=>'~'),
			"<foo>\n~<bar/>\n</foo>",
			'indent_string works');
	},
	qr/Non\-whitespace indent_string supplied/i,
	'weird indent_string raises warning',
);
	
is(indent('<foo>abba<bar bum="1"><quux>xyzzy<baz/>xyzzy<baz><gurgle/></baz></quux><quux/></bar>abba<bar />abba</foo>'),
	do { $_ = <<OUTPUT; chomp; $_; }, 'complicated example works');
<foo>
	abba
	<bar bum="1">
		<quux>
			xyzzy
			<baz/>
			xyzzy
			<baz>
				<gurgle/>
			</baz>
		</quux>
		<quux/>
	</bar>
	abba
	<bar/>
	abba
</foo>
OUTPUT


is(indent('<ul><li>This is a <b>story</b> all about <i>how</i></li><li>My life got <b>flipped</b>; turned <i>upside-down</i>.</li><li></li></ul>',
	element=>{inline=>[qw{b i u span strong em}]}),
	do { $_ = <<OUTPUT; chomp; $_; }, 'example with some inline elements works');
<ul>
	<li>
		This is a <b>story</b> all about <i>how</i>
	</li>
	<li>
		My life got <b>flipped</b>; turned <i>upside-down</i>.
	</li>
	<li/>
</ul>
OUTPUT

is(indent('<ul><li>This is a <b>story</b> all about <i>how</i><div>My life got <b>flipped</b>; turned <i>upside-down</i>.</div></li><li></li></ul>',
	element=>{inline=>[qw{b i u span strong em}]}),
	do { $_ = <<OUTPUT; chomp; $_; }, 'mixed inline and block elements');
<ul>
	<li>
		This is a <b>story</b> all about <i>how</i>
		<div>
			My life got <b>flipped</b>; turned <i>upside-down</i>.
		</div>
	</li>
	<li/>
</ul>
OUTPUT

is(indent(<<'INPUT', element=>{compact=>[qw{li dt dd}],inline=>[qw{b i u span strong em}]}), do { $_ = <<OUTPUT; chomp; $_; }, 'compact elements');
<ul>
 <li>Test 1</li>
 <li>Test <b>2</b></li>
 <li>Test <div>3</div></li>
</ul>
INPUT
<ul>
	<li>Test 1</li>
	<li>Test <b>2</b></li>
	<li>
		Test
		<div>
			3
		</div>
	</li>
</ul>
OUTPUT

is(indent(<<'INPUT', element=>{compact=>[qw{c}],inline=>[qw{i}]}), do { $_ = <<OUTPUT; chomp; $_; }, 'nested compact elements');
<root>
	<c><c>foo</c><c>bar</c></c>
	<c><c>foo</c><i>baz</i></c>
	<c><c>foo</c><b>bat</b></c>
	<c>quux</c>
</root>
INPUT
<root>
	<c><c>foo</c><c>bar</c></c>
	<c><c>foo</c><i>baz</i></c>
	<c>
		<c>foo</c>
		<b>
			bat
		</b>
	</c>
	<c>quux</c>
</root>
OUTPUT

is(indent(<<'INPUT', element=>{preserves_whitespace=>[qw{script style pre xmp textarea}],compact=>[qw{li dt dd}],inline=>[qw{b i u span strong em}]}), do { $_ = <<OUTPUT; chomp; $_; }, 'preformatting');
<ul>
 <li>Test 1</li>
 <li>Test <b>2</b></li>
 <li>Test <div>3</div><pre>lala
foobar</pre></li>
</ul>
INPUT
<ul>
	<li>Test 1</li>
	<li>Test <b>2</b></li>
	<li>
		Test
		<div>
			3
		</div>
		<pre>lala
foobar</pre>
	</li>
</ul>
OUTPUT

is(indent(<<'INPUT', element=>{compact=>['p']}), do { $_ = <<OUTPUT; chomp; $_; }, 'with comments');
<div>
<!-- Comment --><!-- Another Comment -->
<p>Hello World <!--foo--> </p>
<!-- Multiline
Comment -->
</div>
INPUT
<div>
	<!-- Comment -->
	<!-- Another Comment -->
	<p>Hello World<!--foo--></p>
	<!-- Multiline
Comment -->
</div>
OUTPUT

is(indent(<<'INPUT', element=>{inline=>['#comment'],compact=>['p']}), do { $_ = <<OUTPUT; chomp; $_; }, 'with comments inline');
<div>
<!-- Comment --><!-- Another Comment -->
<p>Hello World <!--foo--> </p>
<!-- Multiline
Comment -->
</div>
INPUT
<div>
	<!-- Comment --><!-- Another Comment -->
	<p>Hello World <!--foo--></p>
	<!-- Multiline
Comment -->
</div>
OUTPUT

is(indent(<<'INPUT', element=>{compact=>['p']}), do { $_ = <<OUTPUT; chomp; $_; }, 'with processing instructions');
<div><?my-pi fooble ?>
<p>Hello World<?my-pi quux?></p>
<?my-pi barble ?></div>
INPUT
<div>
	<?my-pi fooble ?>
	<p>Hello World<?my-pi quux?></p>
	<?my-pi barble ?>
</div>
OUTPUT

done_testing;
