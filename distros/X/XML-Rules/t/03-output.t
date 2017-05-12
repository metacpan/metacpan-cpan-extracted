#!perl -T

use strict;
use warnings;
use Test::More tests => 60;
use Data::Dumper;
use Encode qw(encode);

use XML::Rules;

my $xml = <<'*END*';
<data version="1.0">
	<foo attr="ahoj">cau</foo>
	<bar/>
	<baz>xxx&quot;xxx</baz>
	<baz>yyyy</baz>
</data>
*END*

my $data_utf8 = "P\x{159}\x{ed}li\x{17e} \x{17e}lu\x{b4}tou\x{10d}k\x{fd} k\x{fa}\x{148} \x{fa}p\x{11b}l \x{161}\x{ed}len\x{e9} \x{f3}dy.";
	# in case you wonder ... The crazy looking stuff above is a Czech sentence commonly used to test the encodings. It contains all accentuated characters used in Czech and still kinda makes sense.
	# It translates as "Too yellow horse moaned crazy odes." I did say "kinda" ;-)
my $data_windows = encode( 'windows-1250', $data_utf8);
my $data_latin2 = encode( 'ISO-8859-2', $data_utf8);

my $parser = XML::Rules->new(
	rules => [
		_default => 'raw',
#		data => 'as is',
	],
);

my $res = $parser->parse($xml);
#print Dumper($res);
my $new_xml = $parser->ToXML(@$res) . "\n";
#print $new_xml;
#exit;
is( $new_xml, $xml, "Parse and output");


{
	my $res = $parser->ToXML( 'data', 'some <important> "content"');
	is( $res, '<data>some &lt;important&gt; &quot;content&quot;</data>', "Tag with content only");
}

{
	my $res = $parser->ToXML( 'data', {_content => 'some <important> "content"'});
	is( $res, '<data>some &lt;important&gt; &quot;content&quot;</data>', "Tag with content as attribute");
}

{
	my $res = $parser->ToXML( 'data', {str => 'some <important> "content"'});
	is( $res, '<data str="some &lt;important&gt; &quot;content&quot;"/>', "Tag with one attribute");
}

{
	my $res = $parser->ToXML( 'data', {str => 'string', _content => 'some <important> "content"'});
	is( $res, '<data str="string">some &lt;important&gt; &quot;content&quot;</data>', "Tag with one attribute and content");
}

{
	my $res = $parser->ToXML( 'data', {str => 'some <important> "content"', other => 156});
	ok(
		(
		$res eq '<data str="some &lt;important&gt; &quot;content&quot;" other="156"/>'
		or
		$res eq '<data other="156" str="some &lt;important&gt; &quot;content&quot;"/>'
		),
		"Tag with two attributes"
	);
}

{
	my $res = $parser->ToXML( 'data', '');
	is( $res, '<data></data>', "Tag with empty string content");
}

{
	my $res = $parser->ToXML( 'data', undef);
	is( $res, '<data/>', "Tag with no content");
}

{
	my $res = $parser->ToXML( 'data', {});
	is( $res, '<data/>', "Tag with no content");
}

{
	my $res = $parser->ToXML( 'data', {x => 5});
	is( $res, '<data x="5"/>', "Tag with no content and one attribute");
}

{
	my $res = $parser->ToXML( 'data', {y => 10, x => 5, z => 99});
	is( $res, '<data x="5" y="10" z="99"/>', "Tag with no content and three attributes");
}

{
	my $res = $parser->ToXML( 'data', {x => q{Jose "d'Artagnan" Razon}});
	is( $res, q{<data x="Jose &quot;d'Artagnan&quot; Razon"/>}, "Tag with no content and one attribute that needs escaping");
}

{
	my $res = $parser->ToXML( 'data', {x => $data_utf8});
	is( $res, qq{<data x="$data_utf8"/>}, "Tag with no content and one attribute with accents");
}

{
	my $res = $parser->ToXML( 'data', {foo => {}});
	is( $res, '<data><foo/></data>', "Tag containg tag with no content");
}

{
	my $res = $parser->ToXML( 'data', {foo => []});
	is( $res, '<data><foo/></data>', "Tag containg tag with no content");
}

{
	my $res = $parser->ToXML( 'data', {foo => ['']});
	is( $res, '<data><foo></foo></data>', "Tag containg tag with empty string content");
}

{ # rules: windows, output: utf8
	my $parser = XML::Rules->new(
		rules => [ _default => 'raw', ],
		encode => 'windows-1250',
		output_encoding => 'utf8',
	);
	my $res = $parser->ToXML( 'data', {x => $data_windows});
	is( $res, qq{<data x="$data_utf8"/>}, "Tag with no content and one attribute with accents (windows->utf8)");
}

{ # rules: windows, output: latin2
	my $parser = XML::Rules->new(
		rules => [ _default => 'raw', ],
		encode => 'windows-1250',
		output_encoding => 'ISO-8859-2',
	);
	my $res = $parser->ToXML( 'data', {x => $data_windows});
	is( $res, qq{<data x="$data_latin2"/>}, "Tag with no content and one attribute with accents (windows->latin2)");
}

{ # rules: utf8, output: latin2
	my $parser = XML::Rules->new(
		rules => [ _default => 'raw', ],
		encode => 'UTF8',
		output_encoding => 'ISO-8859-2',
	);
	my $res = $parser->ToXML( 'data', {x => $data_utf8});
	is( $res, qq{<data x="$data_latin2"/>}, "Tag with no content and one attribute with accents (utf8->latin2)");
}

{
	my $res = $parser->ToXML( 'data', [qw(foo bar baz)]);
	is( $res, '<data>foo</data><data>bar</data><data>baz</data>', "Tag with array of contents");
}

{
	my $res = $parser->ToXML( 'data', [qw(foo)]);
	is( $res, '<data>foo</data>', "Tag with array of contents with a single item");
}

{
	my $res = $parser->ToXML( 'data', []);
	is( $res, '', "Tag with array of contents with no items");
}

{
	my $res = $parser->ToXML( ['data', {id => 1}, qw(foo bar baz)]);
	is( $res, '<data id="1">foo</data><data id="1">bar</data><data id="1">baz</data>', "Tag with an attribute and array of contents");
}

{
	my $res = $parser->ToXML( ['data', {id => 1}, [qw(foo bar baz)]]);
	is( $res, '<data id="1">foobarbaz</data>', "Tag with an attribute and contents as array");
}

{
	my $res = $parser->ToXML( 'data', [{str => 'foo'}, {str => 'bar'}, {str => 'baz'}]);
	is( $res, '<data str="foo"/><data str="bar"/><data str="baz"/>', "Tag with array of attributes");
}

{
	my $res = $parser->ToXML( ['data', {}, {str => 'foo'}, {str => 'bar'}, {str => 'baz'}]);
	is( $res, '<data str="foo"/><data str="bar"/><data str="baz"/>', "Again as arrayref");
}

{
	my $res = $parser->ToXML( ['data', {str => 'foo'}, {str => 'bar'}, {str => 'baz'}]);
	is( $res, '<data str="bar"/><data str="baz"/>', "Overwrite attribute hashes");
}

{
	my $res = $parser->ToXML( ['data' => {name => 'foo'}, {str => 'bar'}, {str => 'baz'}]);
	is( $res, '<data name="foo" str="bar"/><data name="foo" str="baz"/>', "Merge attribute hashes");
}


{
	my $res = $parser->ToXML( 'data', {bar => {_content => 'baz'}});
	is( $res, '<data><bar>baz</bar></data>', "Tag with subtag");
}

{
	my $res = $parser->ToXML( ['data', {bar => {_content => 'baz'}}]);
	is( $res, '<data><bar>baz</bar></data>', "Tag with subtag as arrayref");
}

{
	my $res = $parser->ToXML( 'data', {bar => {}});
	is( $res, '<data><bar/></data>', "Tag with empty subtag");
}

{
	my $res = $parser->ToXML( 'data', {attr => 5, bar => {}});
	is( $res, '<data attr="5"><bar/></data>', "Tag with attribute and empty subtag");
}

{
	my $res = $parser->ToXML( 'data', {attr => 5, bar => {a => 42, _content=> 'string'}});
	is( $res, '<data attr="5"><bar a="42">string</bar></data>', "Tag with attribute and subtag with content and attribute");
}


{
	my $res = $parser->ToXML( 'data', 'some <important> "content"', 1);
	is( $res, '<data>some &lt;important&gt; &quot;content&quot;', "Tag with content only, don't close");
}

{
	my $res = $parser->ToXML( 'data', {_content => 'some <important> "content"'}, "don't close");
	is( $res, '<data>some &lt;important&gt; &quot;content&quot;', "Tag with content as attribute, don't close");
}

{
	my $res = $parser->ToXML( 'data', {str => 'some <important> "content"'}, 1);
	is( $res, '<data str="some &lt;important&gt; &quot;content&quot;">', "Tag with one attribute, don't close");
}

{
	my $res = $parser->ToXML( 'data', {str => 'string', _content => 'some <important> "content"'}, 1);
	is( $res, '<data str="string">some &lt;important&gt; &quot;content&quot;', "Tag with one attribute and content, don't close");
}


{
	my $res = $parser->ToXML( 'data', {_content => ['start', [str => 'foo'], 'middle', [str => 'bar'], [str => 'baz'], 'end']});
	is( $res, '<data>start<str>foo</str>middle<str>bar</str><str>baz</str>end</data>', "Tag with mix of text content and subtags");
}

{
	my $res = $parser->ToXML( 'data', {
		at => '5',
		sub => {_content => 'SUBTAG'},
		_content => ['start', [str => 'foo'], 'middle', [str => 'bar'], [str => 'baz'], 'end']
	});
	is( $res, '<data at="5"><sub>SUBTAG</sub>start<str>foo</str>middle<str>bar</str><str>baz</str>end</data>', "Tag with an attribute, subtag in attribute and mix of text content and subtags");
}

# pretty-printing
{
	my $res = $parser->ToXML( 'data', '', 0, '  ', '    ');
	is( $res, "<data></data>", "Tag with empty string content (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', undef, 0, '  ', '    ');
	is( $res, "<data/>", "Tag with no content (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {}, 0, '  ', '    ');
	is( $res, "<data/>", "Tag with no content (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {x => 5}, 0, '  ', '    ');
	is( $res, qq{<data x="5"/>}, "Tag with no content and one attribute (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {y => 10, x => 5, z => 99}, 0, '  ', '    ');
	is( $res, qq{<data x="5" y="10" z="99"/>}, "Tag with no content and three attributes (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', [qw(foo bar baz)], 0, '  ', '    ');
	is( $res, qq{<data>foo</data>\n    <data>bar</data>\n    <data>baz</data>}, "Tag with array of contents (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', [{str => 'foo'}, {str => 'bar'}, {str => 'baz'}], 0, '  ', '    ');
	is( $res, qq{<data str="foo"/>\n    <data str="bar"/>\n    <data str="baz"/>}, "Tag with array of attributes (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {bar => {_content => 'baz'}}, 0, '  ', '    ');
	is( $res, qq{<data>\n      <bar>baz</bar>\n    </data>}, "Tag with subtag (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {bar => {}}, 0, '  ', '    ');
	is( $res, qq{<data>\n      <bar/>\n    </data>}, "Tag with empty subtag (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {attr => 5, bar => {}}, 0, '  ', '    ');
	is( $res, qq{<data attr="5">\n      <bar/>\n    </data>}, "Tag with attribute and empty subtag (pretty-print)");
}

{
	my $res = $parser->ToXML( 'data', {attr => 5, bar => {a => 42, _content=> 'string'}}, 0, '  ', '    ');
	is( $res, qq{<data attr="5">\n      <bar a="42">string</bar>\n    </data>}, "Tag with attribute and subtag with content and attribute (pretty-print)");
}


# more complex examples. modeled after http://www.perlmonks.org/?node_id=787605
{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [children =>
      [
        [girl => 'Shiori'],
        [boy  => 'Yasuke'],
        [boy  => 'Kairi']
      ]
    ]
  ]
]);
	is( $res, qq{<family name="Kawasaki"><father>Yasushisa</father><mother>Chizuko</mother><children><girl>Shiori</girl><boy>Yasuke</boy><boy>Kairi</boy></children></family>}, "Family tree");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        [[girl => 'Shiori']],
        [[boy  => 'Yasuke']],
        [[boy  => 'Kairi']]
    ]
  ]
], 0);
	is( $res, qq{<family name="Kawasaki"><father>Yasushisa</father><mother>Chizuko</mother><child><girl>Shiori</girl></child><child><boy>Yasuke</boy></child><child><boy>Kairi</boy></child></family>}, "Family tree");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        'Shiori',
        'Yasuke',
        'Kairi'
    ]
  ]
], 0);
	is( $res, qq{<family name="Kawasaki"><father>Yasushisa</father><mother>Chizuko</mother><child>Shiori</child><child>Yasuke</child><child>Kairi</child></family>}, "Family tree");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        {sex => 'f'}, 'Shiori',
        {sex => 'm'}, 'Yasuke',
        {sex => 'm'}, 'Kairi'
    ]
  ]
], 0);
	is( $res, qq{<family name="Kawasaki"><father>Yasushisa</father><mother>Chizuko</mother><child sex="f">Shiori</child><child sex="m">Yasuke</child><child sex="m">Kairi</child></family>}, "Family tree");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        'Shiori',
        {sex => 'm'}, 'Yasuke',
        {sex => 'm'}, 'Kairi'
    ]
  ]
], 0);
	is( $res, qq{<family name="Kawasaki"><father>Yasushisa</father><mother>Chizuko</mother><child>Shiori</child><child sex="m">Yasuke</child><child sex="m">Kairi</child></family>}, "Family tree");
}

#formatted
{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [children =>
      [
        [girl => 'Shiori'],
        [boy  => 'Yasuke'],
        [boy  => 'Kairi']
      ]
    ]
  ]
], 0, ' ', '');
	is( $res, qq{<family name="Kawasaki">
 <father>Yasushisa</father>
 <mother>Chizuko</mother>
 <children>
  <girl>Shiori</girl>
  <boy>Yasuke</boy>
  <boy>Kairi</boy>
 </children>
</family>}, "Family tree (formatted)");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        [[girl => 'Shiori']],
        [[boy  => 'Yasuke']],
        [[boy  => 'Kairi']]
    ]
  ]
], 0, ' ', '');
	is( $res, qq{<family name="Kawasaki">
 <father>Yasushisa</father>
 <mother>Chizuko</mother>
 <child>
  <girl>Shiori</girl>
 </child>
 <child>
  <boy>Yasuke</boy>
 </child>
 <child>
  <boy>Kairi</boy>
 </child>
</family>}, "Family tree (formatted)");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        'Shiori',
        'Yasuke',
        'Kairi'
    ]
  ]
], 0, ' ', '');
	is( $res, qq{<family name="Kawasaki">
 <father>Yasushisa</father>
 <mother>Chizuko</mother>
 <child>Shiori</child>
 <child>Yasuke</child>
 <child>Kairi</child>
</family>}, "Family tree (formatted)");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        {sex => 'f'}, 'Shiori',
        {sex => 'm'}, 'Yasuke',
        {sex => 'm'}, 'Kairi'
    ]
  ]
], 0, ' ', '');
	is( $res, qq{<family name="Kawasaki">
 <father>Yasushisa</father>
 <mother>Chizuko</mother>
 <child sex="f">Shiori</child>
 <child sex="m">Yasuke</child>
 <child sex="m">Kairi</child>
</family>}, "Family tree (formatted)");
}

{
	my $res = $parser->ToXML( [ family => { name => 'Kawasaki' },
  [
    [father => 'Yasushisa' ],
    [mother => 'Chizuko' ],
    [child =>
        'Shiori',
        {sex => 'm'}, 'Yasuke',
        {sex => 'm'}, 'Kairi'
    ]
  ]
], 0, ' ', '');
	is( $res, qq{<family name="Kawasaki">
 <father>Yasushisa</father>
 <mother>Chizuko</mother>
 <child>Shiori</child>
 <child sex="m">Yasuke</child>
 <child sex="m">Kairi</child>
</family>}, "Family tree (formatted)");
}
