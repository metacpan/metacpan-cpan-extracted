
use Test::More tests => 13;
BEGIN { use_ok('XML::XForms::Validate') };

my $v;
sub _($) {
	return $v->normalize($_[0]->{''})->toStringC14N if ref($_[0]);
	return $_[0];
}

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms'>
	<xf:model id="a">
		<xf:submission id="sub1"/>
		<xf:instance>
<data>
	<frobozz><a/></frobozz>
	<gna>123</gna>
	<yip yip="1">aaa</yip>
	<foo>
		<bar>1</bar>
		<baz>2</baz>
		<baz>3</baz>
	</foo>
	<wib/>
</data>
		</xf:instance>
		<xf:bind nodeset="foo/bar" relevant="../baz[1] > 5"/>
		<xf:bind nodeset="yip/@yip" relevant=".. = 'bbb'"/>
	</xf:model>
	<xf:input ref="frobozz"/>
	<xf:input ref="frobozz/a"/>
	<xf:input ref="gna"/>
	<xf:input ref="yip"/>
	<xf:input ref="yip/@yip"/>
	<xf:input ref="foo/bar"/>
	<xf:input ref="foo/baz[1]"/>
	<xf:input ref="foo/baz[2]"/>
	<xf:input ref="wib"/>
</doc>
EOX

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

my $result;

is(_ $v->validate(input => \'<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
	<foo>
		<baz>yadda</baz>
		<baz>6</baz>
	</foo>
	<wib/>
</data>'),
	'<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
	<foo>
		<bar>1</bar>
		<baz>yadda</baz>
		<baz>6</baz>
	</foo>
	<wib></wib>
</data>',
	'non-relevant node omitted'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	$result,
	'relevant node included'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Missing relevant nodes: /data/yip',
	'missing relevant node'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
</data>';

is(_ $v->validate(input => \$result),
	'Child elements missing: foo, wib (/data)',
	'child element missing'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Child elements missing: baz (/data/foo)',
	'child element missing (nested)'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
	<foo>
		<bar>yay</bar>
		<baz>1</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Submission contains non-relevant node: /data/foo/bar',
	'additional non-relevant node'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">bbb</yip>
	<yip>bbb</yip>
	<foo>
		<bar>yay</bar>
		<baz>1</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Original node "foo" doesn\'t match "yip" (/data/yip[2])',
	'additional node'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna gna="1">345</gna>
	<yip yip="1">bbb</yip>
	<foo>
		<bar>yay</bar>
		<baz>1</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Additional attributes found: gna (/data/gna)',
	'additional attribute'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip>bbb</yip>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Missing relevant nodes: /data/yip/@yip',
	'missing attribute'
);

is(_ $v->validate(input => \'<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip>aaa</yip>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>'),
	'<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">aaa</yip>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>',
	'non-relevant attribute'
);

$result = '<data>
	<frobozz><a>1</a></frobozz>
	<gna>345</gna>
	<yip yip="1">aaa</yip>
	<foo>
		<bar>yay</bar>
		<baz>7</baz>
		<baz>3</baz>
	</foo>
	<wib></wib>
</data>';

is(_ $v->validate(input => \$result),
	'Submission contains non-relevant node: /data/yip/@yip',
	'additional non-relevant attribute'
);

