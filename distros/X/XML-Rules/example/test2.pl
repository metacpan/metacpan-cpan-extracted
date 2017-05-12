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
#	bogus => sub {}, # means "returns no value. The subtags ARE processed.
	'^bogus' => undef, # means "ignore". The subtags ARE NOT processed.
	address => 'no content',
	person => 'no content array',
	doc => sub {$_[1]->{person}}, #'pass no content',
	foo => sub {print "FOOOOOOOO\n"},
);

my $parser = new XML::Rules (
	rules => \%rules,
	# other options
);

my $result = $parser->parsestring($xml);

use Data::Dumper;
print Dumper($result);