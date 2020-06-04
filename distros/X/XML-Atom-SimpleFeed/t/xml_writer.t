use strict;
use warnings;

use XML::Atom::SimpleFeed;

package XML::Atom::SimpleFeed;
use Test::More tests => 9;
BEGIN { eval { require Test::LongString; Test::LongString->import; 1 } or *is_string = \&is; }

sub _ok {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ( $fn, $in, $out, $desc ) = @_;
	is_string $fn->( $in ), $out, $desc;
}

_ok \&xml_escape,
	qq(<\x{FF34}\x{FF25}\x{FF33}\x{FF34} "&' d\xE3t\xE3>),
	qq(&lt;&#65332;&#65317;&#65331;&#65332; &#34;&#38;&#39; d&#227;t&#227;&gt;),
	'XML tag content is properly encoded';

_ok sub { xml_encoding 'utf8', \&xml_escape, @_ },
	qq(<\x{FF34}\x{FF25}\x{FF33}\x{FF34} "&' d\xE3t\xE3>),
	qq(&lt;\x{ef}\x{bc}\x{b4}\x{ef}\x{bc}\x{a5}\x{ef}\x{bc}\x{b3}\x{ef}\x{bc}\x{b4} &#34;&#38;&#39; d\x{c3}\x{a3}t\x{c3}\x{a3}&gt;),
	'... even under other encodings';

_ok \&xml_attr_escape,
	qq(<\x{FF34}\x{FF25}\x{FF33}\x{FF34}\n"&'\rd\xE3t\xE3>),
	qq(&lt;&#65332;&#65317;&#65331;&#65332;&#10;&#34;&#38;&#39;&#13;d&#227;t&#227;&gt;),
	'XML attribute content is properly encoded';

_ok sub { xml_encoding 'utf8', \&xml_attr_escape, @_ },
	qq(<\x{FF34}\x{FF25}\x{FF33}\x{FF34}\n"&'\rd\xE3t\xE3>),
	qq(&lt;\x{ef}\x{bc}\x{b4}\x{ef}\x{bc}\x{a5}\x{ef}\x{bc}\x{b3}\x{ef}\x{bc}\x{b4}&#10;&#34;&#38;&#39;&#13;d\x{c3}\x{a3}t\x{c3}\x{a3}&gt;),
	'... even under other encodings';

_ok \&xml_string,
	qq(Test <![CDATA[<CDATA>]]> sections),
	qq(Test &lt;CDATA&gt; sections),
	'CDATA sections are properly flattened';

is xml_tag( 'br' ), '<br/>', 'simple tags are self-closed';
is xml_tag( 'b', 'foo', '<br/>' ), '<b>foo<br/></b>', 'tags with content are properly formed';
is xml_tag( [ 'br', clear => 'left' ] ), '<br clear="left"/>', 'simple tags can have attributes';
is xml_tag( [ 'b', style => 'color: red' ], 'foo', '<br/>' ), '<b style="color: red">foo<br/></b>', 'simple tags can have attributes';
