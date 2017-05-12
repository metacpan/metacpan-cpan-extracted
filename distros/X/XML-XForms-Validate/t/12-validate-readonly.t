
use Test::More tests => 12;
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
	<wib>23</wib>
	<yadda/>
</data>
		</xf:instance>
		<xf:bind nodeset="frobozz" readonly="true()">
			<xf:bind nodeset="a" required="false()" id="a"/>
		</xf:bind>
		<xf:bind nodeset="instance('')/gna" readonly="true()" id="b"/>
		<xf:bind nodeset="/data/yip" readonly="true()" id="c"/>
		<xf:bind nodeset="foo/bar/text()" readonly="true()" id="d"/>
		<xf:bind nodeset="foo/bar/@blub" readonly="true()" id="e"/>
		<xf:bind nodeset="foo/baz[1]" readonly="false()"/>
		<xf:bind nodeset="yadda" calculate="42*23"/>
	</xf:model>
	<xf:input ref="wib"/>
	<xf:input bind="a"/>
	<xf:input bind="b"/>
	<xf:input bind="c"/>
	<xf:input bind="d"/>
	<xf:input bind="e"/>
</doc>
EOX

my $result = '<data>
	<frobozz>1<a></a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>';

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => \'<data>
	<frobozz>222<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly node with children, calculate ignore'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a>1</a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly inherited'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>345</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly via instance()'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip></yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly via absolute XPath'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>5</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly because not referenced'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">2</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly text node'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="3">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	$result,
	'readonly attribute'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>4</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>'),
	'<data>
	<frobozz>1<a></a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>23</wib>
	<yadda>966</yadda>
</data>',
	'read-only via missing ui reference'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>42</wib>
	<yadda>966</yadda>
</data>'),
	'<data>
	<frobozz>1<a></a>2</frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>42</wib>
	<yadda>966</yadda>
</data>',
	'read-write via ui reference'
);

is(_ $v->validate(input => \'<data>
	<frobozz>1<a/></frobozz>
	<gna>123</gna>
	<yip>aaa</yip>
	<foo>
		<bar blub="2">1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib>42</wib>
	<yadda>966</yadda>
</data>'),
	'Text node missing for /data/frobozz/text()[2]',
	'text node missing'
);
