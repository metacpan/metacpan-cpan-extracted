
use Test::More tests => 12;
BEGIN { use_ok('XML::XForms::Validate') };

my $v;
sub _($) {
	return $v->normalize($_[0]->{''})->toStringC14N if ref($_[0]);
	return $_[0];
}

my $doc = <<'EOX';
<doc xmlns:xf='http://www.w3.org/2002/xforms' xmlns:xsd='http://www.w3.org/2001/XMLSchema-datatypes'>
	<xf:model id="modela">
		<xf:submission id="sub1"/>
		<xf:bind nodeset="str" type="xsd:string"/>
		<xf:bind nodeset="int" type="xsd:integer"/>
		<xf:bind nodeset="dbl" type="xsd:double"/>
		<xf:bind nodeset="date" type="xsd:dateTime"/>
		<xf:bind nodeset="dtd" type="xf:dayTimeDuration"/>
		<xf:bind nodeset="ymd" type="xf:yearMonthDuration"/>
		<xf:bind nodeset="bool" type="xsd:boolean"/>
		<xf:bind nodeset="pos" type="xsd:positiveInteger"/>
		<xf:bind nodeset="item" type="xf:listItem"/>
		<xf:bind nodeset="list" type="xf:listItems"/>
	</xf:model>
	<xf:input ref="str"/>
	<xf:input ref="int"/>
	<xf:input ref="dbl"/>
	<xf:input ref="date"/>
	<xf:input ref="dtd"/>
	<xf:input ref="ymd"/>
	<xf:input ref="bool"/>
	<xf:input ref="pos"/>
	<xf:input ref="item"/>
	<xf:input ref="list"/>
</doc>
EOX

my @tags = qw(str int dbl date dtd ymd bool pos item list);
sub inst { return \('<instanceData>'.join('', map { '<'.$tags[$_].'>'.$_[$_].'</'.$tags[$_].'>' } 0..$#tags).'</instanceData>') }

$v = new XML::XForms::Validate(xforms => \$doc);
isa_ok($v, 'XML::XForms::Validate');

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def")),
	${inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def")},
	'type basics'
);

is(_ $v->validate(input => inst("abc", "a", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/int (integer)',
	'integer'
);

is(_ $v->validate(input => inst("abc", "123", "1e.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/dbl (double)',
	'double'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59", "P1DT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/date (dateTime)',
	'dateTime'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "PDT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/dtd (dayTimeDuration)',
	'dayTimeDuration'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M1H", "true", "123", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/ymd (yearMonthDuration)',
	'yearMonthDuration'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "1", "123", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/bool (boolean)',
	'boolean'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "0", "123-abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/pos (positiveInteger)',
	'positiveInteger'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "123", "123 abc", "123-abc 345-def")),
	'Type mismatch for /instanceData/item (listItem)',
	'listItem'
);

is(_ $v->validate(input => inst("abc", "123", "1.23", "2008-01-01T23:59:00", "P1DT4H", "P1Y3M", "true", "123", "123-abc", "123-abc 345-def ")),
	'Type mismatch for /instanceData/list (listItems)',
	'listItems'
);

