$|=1;
use XML::Rules;

$xml = <<'*END*';
<doc>
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
  <address>
   <street>Washington st.</street>
   <city>Old Creek</city>
   <country>The US</country>
   <bogus>bleargh</bogus>
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
	_default => 'content',
	'^bogus' => undef, # means "ignore"
	address => sub {delete $_[1]->{_content}; $_[1]},
	person => 'as array',
	doc => 'pass no content',
	foo => sub {print "FOOOOOOOO\n"},
	'/^.name$/' => sub {print "Found a name!\n"; $_[0] => $_[1]->{_content}},
);

my $parser = new XML::Rules (
	rules => \%rules,
	# other options
);

my $result = $parser->parsestring($xml);

use Data::Dumper;
print Dumper($result);