
use Test::More tests => 12;
BEGIN { use_ok('XML::XForms::Validate') };

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms'>
	<xf:model id="a">
		<xf:submission id="def"/>
		<xf:instance id="i1">
			<data>
				<a>123</a>
				<b>bbB</b>
				<c><d>f</d></c>
			</data>
		</xf:instance>
		<xf:instance id="i2">
			<data2><xxx>xxx</xxx></data2>
		</xf:instance>
	</xf:model>
	<xf:model id="b">
		<xf:submission bind="foo" />
		<xf:submission id="defb" bind="b1" />
		<xf:submission id="defc" ref="bar" />
		<xf:bind id="b1" nodeset="baz"/>
		<xf:bind id="foo" nodeset="baf"/>
	</xf:model>
	<xf:model id="c"/>
	<xf:input model="b" ref="foo"/>
	<xf:input ref="a"/>
	<xf:group model="b">
		<xf:input ref="bar"/>
	</xf:group>
</doc>
EOX

my $v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

ok(exists $v->{submissions}{def}, 'submission found');

is_deeply($v->{submissions}{def}, { id => 'def', ref => [ '/' ] }, 'submission correct');

$v = new XML::XForms::Validate(xforms => \$doc, model => 'b');
isa_ok($v, 'XML::XForms::Validate');

ok(!exists $v->{submissions}{def}, 'no foreign submission found');

ok(exists $v->{submissions}{defb}, 'submission found');

ok(exists $v->{submissions}{defc}, 'submission 2 found');

is($v->{submissions}{defb}, $v->{submissions}{''}, 'default submission');

is_deeply($v->{submissions}{defb}, { id => 'defb', ref => [ 'baz' ] }, 'submission correct');

is_deeply($v->{submissions}{defc}, { id => 'defc', ref => [ 'bar' ] }, 'submission 2 correct');

$v = undef;
eval { $v = new XML::XForms::Validate(xforms => \$doc, model => 'c') };
ok($@, 'submission missing');

