$|=1;
use XML::Rules;
use Data::Dumper;

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
  <phones>
   <phone type="home">123-456-7890</phone>
   <phone type="office">663-486-7890</phone>
   <phone type="fax">663-486-7000</phone>
  </phones>
 </person>
 <person>
  <fname>John</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
  <address>
   <street>Grant's st.</street>
   <city>New Creek</city>
   <country>Canada</country>
   <bogus>sdrysdfgtyh degtrhy <foo>degtrhy werthy</foo>werthy drthyu</bogus>
  </address>
  <phones>
   <phone type="office">663-486-7891</phone>
  </phones>
 </person>
</doc>
*END*

%rules = (
	_default => 'content',
	'^bogus' => undef, # means "ignore"
	address => sub {address => "$_[1]->{street}, $_[1]->{city} ($_[1]->{country})"},
	person => sub {
		#print Dumper($_[2], $_[3]);
		return '@person' => "$_[1]->{lname}, $_[1]->{fname}\n<$_[1]->{email}>\n$_[1]->{address}"
	},
	doc => sub { join "\n\n", @{$_[1]->{person}} },
);

my $parser = new XML::Rules (
	rules => \%rules,
	# other options
);

use Data::Dumper;
print Dumper($parser);

print "About to parse\n";
my $result = $parser->parsestring($xml);

print "Result:\n$result\n";