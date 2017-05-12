
use Test::More tests => 9;
BEGIN { use_ok('XML::XForms::Validate') };

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
	<xf:model id="a">
		<xf:submission id="def"/>
		<xf:instance id="i1">
			<data xsi:noNamespaceSchemaLocation="t/abc.xsd">
				<a>123</a>
				<b>bbB</b>
				<c><d>f</d></c>
			</data>
		</xf:instance>
		<xf:instance id="i2">
			<data2 xmlns="urn:xxx" xsi:noNamespaceSchemaLocation="t/abc.xsd" xsi:schemaLocation="urn:local t/local.xsd urn:xxx t/xxx.xsd"><xxx>xxx</xxx></data2>
		</xf:instance>
	</xf:model>
	<xf:model id="b">
		<xf:submission id="defb" bind="b1" />
		<xf:submission id="defc" ref="bar" />
		<xf:bind id="b1" nodeset="baz"/>
	</xf:model>
	<xf:input model="b" ref="foo"/>
	<xf:input ref="a"/>
	<xf:group model="b">
		<xf:input ref="bar"/>
	</xf:group>
</doc>
EOX

my $v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

ok(exists $v->{schemas}{i1}, 'schema found');

ok(exists $v->{schemas}{i2}, 'schema 2 found');

ok(!exists $v->{schemas}{''}, 'no default schema');

eval { $v->{schemas}{i1}->validate($v->{parser}->parse_string('<data>
	<a>123</a>
	<b>bbB</b>
	<c><d>f</d></c>
</data>')) };

is($@, '', 'correct schema loaded');

eval { $v->{schemas}{i1}->validate($v->{parser}->parse_string('<data>
	<a>a123</a>
	<b>bbB</b>
	<c><d>f</d></c>
</data>')) };

ok($@, 'schema works');

$v = new XML::XForms::Validate(xforms => \$doc, model => 'b');
isa_ok($v, 'XML::XForms::Validate');

ok(!%{$v->{schemas}}, 'no foreign schema found');
