$|=1;
use XML::Rules;

$xml = <<'*END*';
<doc>
 <person xmlns="http://jenda.krynicky.cz/xmlns/testXMLNS/person" xmlns:foo="http://jenda.krynicky.cz/xmlns/testXMLNS/foo">
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
  <address>
   <street>Washington st.</street>
   <city>Old Creek</city>
   <country>The US</country>
   <bogus>bleargh</bogus>
   <foo:bogus>bleargh</foo:bogus>
  </address>
 </person>
 <person>
  <fname>John</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
  <address>
   <street>Grant's st.</street>
   <city>New Creek</city>
   <country>Canada</country>
   <bogus>sdrysdfgtyh <foo>degtrhy werthy</foo> drthyu</bogus>
  </address>
 </person>
</doc>
*END*

%rules = (
	_default => 'as is',
	person => 'as array no content',
);

my $parser = new XML::Rules (
	rules => \%rules,
	namespaces => {
		reverse 'ahoj' => 'http://jenda.krynicky.cz/xmlns/testXMLNS/other',
#		'p' => 'http://jenda.krynicky.cz/xmlns/testXMLNS/person',
		'' => 'http://jenda.krynicky.cz/xmlns/testXMLNS/person',
		'fxx' => 'http://jenda.krynicky.cz/xmlns/testXMLNS/foo',
	},
	# other options
);

my $result = $parser->parsestring($xml);

use Data::Dumper;
print Dumper($result);