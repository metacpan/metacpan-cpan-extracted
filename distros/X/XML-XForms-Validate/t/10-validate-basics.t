
use Test::More tests => 10;
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
				<yip>aaa</yip>
				<foo>
					<bar>1</bar>
					<baz>2</baz>
					<baz>3</baz>
				</foo>
			</data>
		</xf:instance>
		<xf:bind nodeset="frobozz" readonly="false()">
			<xf:bind nodeset="a" required="false()" id="a"/>
		</xf:bind>
		<xf:setvalue ref="frobozz"/>
	</xf:model>
	<xf:model id="b">
		<xf:submission id="sub2"/>
		<xf:submission id="sub3" bind="b1"/>
		<xf:submission id="sub4" ref="bar"/>
		<xf:bind nodeset="baz" id="b1" />
		<xf:bind nodeset="foo" calculate="42*23" />
		<xf:bind nodeset="bar" relevant="0 &lt; 1" />
		<xf:bind nodeset="quux" constraint="starts-with(., '$')" />
		<xf:bind nodeset="bozo" type="xsd:number" readonly="false()"/>
		<xf:bind nodeset="lox" required="../foo = 42*23" />
	</xf:model>
	<xf:input model="b" ref="foo"/>
	<xf:input ref="a"/>
	<xf:input ref="gna"/>
	<xf:input ref="yip"/>
	<xf:group ref="foo">
		<xf:input ref="bar"/>
		<xf:input ref="baz"/>
	</xf:group>
	<xf:input bind="a" model="a"/>
	<xf:input model="b" bind="b1"/>
	<xf:group model="b">
		<xf:input ref="bar"/>
	</xf:group>
</doc>
EOX

my $result = '<data>
				<frobozz><a>1</a></frobozz>
				<gna>345</gna>
				<yip>bbb</yip>
				<foo>
					<bar>fump</bar>
					<baz>yadda</baz>
					<baz>3</baz>
				</foo>
			</data>';

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => [ a => 1, gna => 345, yip => 'bbb', bar => 'fump', baz => 'yadda', baz => 3 ]),
	$result,
	'arrayref input'
);

is(_ $v->validate(input => { a => [ 1 ], gna => 345, yip => 'bbb', bar => 'fump', baz => [ 'yadda', 3 ] }),
	$result,
	'hashref input'
);

is(_ $v->validate(input => \$result),
	$result,
	'XML input'
);


$v = new XML::XForms::Validate(xforms => \$doc, model => 'b');
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => \'<instanceData>
	<foo>966</foo>
	<baz>222</baz>
	<bar>1</bar>
</instanceData>'),
	'<instanceData><foo>966</foo><baz>222</baz><bar>1</bar></instanceData>',
	'result instance');

is(_ $v->validate(input => \'<baz>1</baz>', submission => 'sub3'),
	'<instanceData><foo></foo><baz>1</baz><bar></bar></instanceData>',
	'submission w/ bind'
);

is(_ $v->validate(input => \'<bar>1</bar>', submission => 'sub4'), 
	'<instanceData><foo></foo><baz></baz><bar>1</bar></instanceData>',
	'submission w/ ref'
);

is($v->validate(input => \'<foo>1</foo>', submission => 'sub3'),
	'Submission does not match subtree reference (baz)',
	'wrong submission reference'
);

