
use Test::More tests => 3;
BEGIN { use_ok('XML::XForms::Validate') };

my $v;
sub _($) {
	return $v->normalize($_[0]->{''})->toStringC14N if ref($_[0]);
	return $_[0];
}

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
	<xf:model id="a">
		<xf:submission id="def"/>
		<xf:instance id="i1">
			<data>
	<a src="false">x</a>
	<a src="1">x</a>
	<b src="a">x</b>
	<b src="b">x</b>
	<c src1="13" src2="23" src3="42">x</c>
	<d src1="13" src2="23" src3="42">x</d>
	<e src1="13" src2="23" src3="42">x</e>
	<f src1="" src2="23" src3="42">x</f>
	<g>x</g>
	<h src="2002-01-01">x</h>
	<h src="1969-12-31">x</h>
	<i src="2002-01-01T12:00:00">x</i>
	<i src="1969-12-31T12:00:00">x</i>
	<j src="P1Y2M3DT10H30M1.5S">x</j>
	<k src="P1Y2M3DT10H30M1.5S">x</k>
</data>
		</xf:instance>
		<xf:bind nodeset="a" calculate="boolean-from-string(@src)"/>
		<xf:bind nodeset="b" calculate="if(@src = 'a',42+23,42*23)"/>
		<xf:bind nodeset="c" calculate="avg(@*)"/>
		<xf:bind nodeset="d" calculate="min(@*)"/>
		<xf:bind nodeset="e" calculate="max(@*)"/>
		<xf:bind nodeset="f" calculate="count-non-empty(@*)"/>
		<xf:bind nodeset="g" calculate="property('conformance-level')"/>
		<xf:bind nodeset="h" calculate="days-from-date(@src)"/>
		<xf:bind nodeset="i" calculate="seconds-from-dateTime(@src)"/>
		<xf:bind nodeset="j" calculate="seconds(@src)"/>
		<xf:bind nodeset="k" calculate="months(@src)"/>
	</xf:model>
</doc>
EOX

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

my $result = '<data>
	<a src="false">false</a>
	<a src="1">true</a>
	<b src="a">65</b>
	<b src="b">966</b>
	<c src1="13" src2="23" src3="42">26</c>
	<d src1="13" src2="23" src3="42">13</d>
	<e src1="13" src2="23" src3="42">42</e>
	<f src1="" src2="23" src3="42">2</f>
	<g>full</g>
	<h src="2002-01-01">11688</h>
	<h src="1969-12-31">-1</h>
	<i src="2002-01-01T12:00:00">1009886400</i>
	<i src="1969-12-31T12:00:00">-43200</i>
	<j src="P1Y2M3DT10H30M1.5S">297001.5</j>
	<k src="P1Y2M3DT10H30M1.5S">14</k>
</data>';

is(_ $v->validate(input => \$result), $result, 'XPath functions');
