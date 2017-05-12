
use Test::More tests => 6;
BEGIN { use_ok('XML::XForms::Validate') };

my $v;
sub _($) {
	return $v->normalize($_[0]->{''})->toStringC14N if ref($_[0]);
	return $_[0];
}

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms'>
	<xf:model id="modela">
		<xf:submission id="sub1"/>
		<xf:instance>
<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda/>
</data>
		</xf:instance>
		<xf:bind nodeset="frobozz" readonly="true()">
			<xf:bind nodeset="a" calculate="/data/yadda + //@blub" id="a"/>
		</xf:bind>
		<xf:bind nodeset="foo/bar/@blub" calculate="../../../yadda - 1" id="e"/>
		<xf:bind nodeset="yadda" calculate="42*23"/>
		<xf:bind nodeset="wib" calculate="sum(../foo/baz)"/>
	</xf:model>
	<xf:input ref="wib"/>
	<xf:input bind="a"/>
	<xf:input bind="e"/>
</doc>
EOX

my $result = '<data>
	<frobozz>1<a>1931</a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="965">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>';

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => \$result),
	$result,
	'calculate including recursive dependencies, readonly ignore'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a>968</a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>'),
	'Calculation mismatch for /data/foo/bar/@blub (../../../yadda - 1): expected "965", found "2"',
	'calculate mismatch'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a>1931</a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="965">1</bar>
		<baz>3</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>'),
	'<data>
	<frobozz>1<a>1931</a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="965">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>5</wib>
	<yadda>966</yadda>
</data>',
	'calculate dependency on readonly value'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a>1931</a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="965">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>2</wib>
	<yadda>966</yadda>
</data>'),
	'Calculation mismatch for /data/wib (sum(../foo/baz)): expected "5", found "2"',
	'calculate mismatch on read-write value'
);
