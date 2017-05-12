
use Test::More tests => 11;
BEGIN { use_ok('XML::XForms::Validate') };

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms'>
	<xf:model id="a">
		<xf:submission id="s1"/>
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
		<xf:submission id="s2"/>
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

ok(exists $v->{instances}{''}, 'default instance found');

ok(exists $v->{instances}{i1}, 'instance 1 found');

ok(exists $v->{instances}{i2}, 'instance 2 found');

is($v->normalize($v->{instances}{i2})->toStringC14N, '<data2><xxx>xxx</xxx></data2>', 'correct instance found');

is($v->{instances}{''}, $v->{instances}{i1}, 'default instance');

isn't($v->{instances}{''}, $v->{instances}{i2}, 'secondary instance');

$v = new XML::XForms::Validate(xforms => \$doc, model => 'b');
isa_ok($v, 'XML::XForms::Validate');

ok(exists $v->{instances}{''}, 'instance created');

is($v->normalize($v->{instances}{''})->toStringC14N, '<instanceData><foo></foo><bar></bar></instanceData>', 'correct instance created');
