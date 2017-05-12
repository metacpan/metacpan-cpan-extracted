
use Test::More tests => 8;
BEGIN { use_ok('XML::XForms::Validate') };

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms'>
	<xf:model id="a">
		<xf:submission id="s1"/>
		<xf:instance>
			<data>
				<frobozz><a/></frobozz>
			</data>
		</xf:instance>
		<xf:bind nodeset="frobozz" readonly="true()">
			<xf:bind nodeset="a" required="false()" id="a"/>
		</xf:bind>
		<xf:setvalue ref="frobozz"/>
	</xf:model>
	<xf:model id="b">
		<xf:submission id="s2"/>
		<xf:bind nodeset="baz" readonly="true()" id="b1" />
		<xf:bind nodeset="foo" calculate="42*23" />
		<xf:bind nodeset="bar" relevant="1 &lt; 0" />
		<xf:bind nodeset="quux" constraint="starts-with(., '$')" />
		<xf:bind nodeset="bozo" type="xsd:number" readonly="false()"/>
		<xf:bind nodeset="lox" required="../foo = 42*23" />
	</xf:model>
	<xf:input model="b" ref="foo"/>
	<xf:input ref="a"/>
	<xf:input bind="a" model="a"/>
	<xf:input model="b" bind="b1"/>
	<xf:group model="b">
		<xf:input ref="bar"/>
	</xf:group>
</doc>
EOX

my $v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is_deeply($v->{refs}[0], [ 'frobozz' ], 'ref from setvalue');

is_deeply($v->{refs}[1], [ 'a' ], 'ref from input');

is_deeply($v->{refs}[2], [ 'frobozz', 'a' ], 'ref from referenced bind');

is(@{$v->{refs}}, 3, 'no refs from binds');

$v = new XML::XForms::Validate(xforms => \$doc, model => 'b');
isa_ok($v, 'XML::XForms::Validate');

is_deeply($v->{refs},
	[ ['foo'], ['baz'], ['bar'] ],
	'model id inheritance'
);
