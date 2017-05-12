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
   <bogus>sdrysdfgtyh degtrhy werthy drthyu</bogus>
  </address>
 </person>
</doc>
*END*

%rules = (
	_default => 'content',
	'^bogus' => undef, # means "ignore"
	address => 'no content',
	person => sub {
print <<"*END*";
Person: $_[1]->{fname} $_[1]->{lname}
Email:  $_[1]->{email}
Address: $_[1]->{address}{street}
         $_[1]->{address}{city}
         $_[1]->{address}{country}

*END*
	},
	doc => sub {},
);

my $parser = new XML::Rules (
	rules => \%rules,
	# other options
);

my $result = $parser->parsestring($xml);

use Data::Dumper;
print Dumper($result);