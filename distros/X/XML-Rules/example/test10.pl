use XML::Rules;

my $xml = <<'*END*';
<?xml version='1.0'?>
<employees>
	<employee>
		<name>John Doe</name>
		<age>43</age>
		<sex>M</sex>
		<department>Operations</department>
	</employee>
	<employee>
		<name>Jane Doe</name>
		<age>31</age>
		<sex>F</sex>
		<department>Accounts</department>
	</employee>
	<employee>
		<name>Be Goode</name>
		<age>32</age>
		<sex>M</sex>
		<department>Human Resources</department>
	</employee>
</employees>
*END*

my $parser = new XML::Rules (
	rules => [
		_default => 'as array trim',
	]
);

my $data = $parser->parse($xml);

use Data::Dumper;
print Dumper($data);

print $parser->toXML( 'employees', $data->{employees}[0]);