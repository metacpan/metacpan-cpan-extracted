
use Test::More tests => 7;
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
	<xf:input model="b" bind="b1"/>
	<xf:group model="b">
		<xf:input ref="bar"/>
	</xf:group>
</doc>
EOX

my $v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

ok(exists $v->{binds}{' 0'}, 'anonymous bind');

ok(exists $v->{binds}{a}, 'nested bind');

delete $_->{node} foreach values %{$v->{binds}};
is_deeply($v->{binds},
	{ ' 0' => {
		id => ' 0',
		nodeset => [ 'frobozz' ],
		readonly => 'true()',
	}, 'a' => {
		id => 'a',
		nodeset => [ 'frobozz', 'a' ],
		required => 'false()',
	} },
	'parsed binds'
);

$v = new XML::XForms::Validate(xforms => \$doc, model => 'b');
isa_ok($v, 'XML::XForms::Validate');

delete $_->{node} foreach values %{$v->{binds}};
is_deeply($v->{binds},
	{ 'b1' => {
		id => 'b1',
		nodeset => [ 'baz' ],
		readonly => 'true()',
	}, ' 0' => {
		id => ' 0',
		nodeset => [ 'foo' ],
		calculate => '42*23',
	}, ' 1' => {
		id => ' 1',
		nodeset => [ 'bar' ],
		relevant => '1 < 0',
	}, ' 2' => {
		id => ' 2',
		nodeset => [ 'quux' ],
		constraint => "starts-with(., '\$')",
	}, ' 3' => {
		id => ' 3',
		nodeset => [ 'bozo' ],
		readonly => 'false()',
		type => 'xsd:number',
	}, ' 4' => {
		id => ' 4',
		nodeset => [ 'lox' ],
		required => '../foo = 42*23',
	} },
	'model item properties'
);
