use strict;
use XML::Rules;

my $xml = <<'*END*';
<?xml version='1.0'?>
<employee>
        <name>John Doe</name>
        <age>43</age>
        <sex>M</sex>
        <department>Operations</department>
</employee>
*END*


{
	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
			employee => 'pass no content',
		]
	);

	my $result = $parser->parsestring($xml);

	use Data::Dumper;
	print Dumper($result);
}

{
	my $parser = new XML::Rules (
		rules => [
			_default => 'content',
			employee => sub {print "$_[1]->{name} is $_[1]->{age} years old and works in the $_[1]->{department} section\n"},
		]
	);

	$parser->parsestring($xml);
}
print "\n\n";
{
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
			_default => 'content',
			employee => sub {print "$_[1]->{name}\nAge/Sex: $_[1]->{age}/$_[1]->{sex}\nDepartment: $_[1]->{department} section\n\n"},
		]
	);

	$parser->parsestring($xml);
}