$|=1;
use XML::Rules;

my $xml = <<'*END*';
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

my $parser = new XML::Rules (
	rules => [
		_default => sub {$_[0] => $_[1]->{_content}},
		'fname,lname' => sub {$_[0] => $_[1]->{_content}},
		'^bogus' => undef,
		address => sub {address => "$_[1]->{street}, $_[1]->{city} ($_[1]->{country})"},
		phone => sub {$_[1]->{type} => $_[1]->{_content}},
			# let's use the "type" attribute as the key and the content as the value
		phones => sub {delete $_[1]->{_content}; %{$_[1]}},
			# remove the text content and pass along the type => content from the child nodes
		person => sub { # lets print the values, all the data is readily available in the attributes
			print "$_[1]->{lname}, $_[1]->{fname} <$_[1]->{email}>\n";
			print "Home phone: $_[1]->{home}\n" if $_[1]->{home};
			print "Office phone: $_[1]->{office}\n" if $_[1]->{office};
			print "Fax: $_[1]->{fax}\n" if $_[1]->{fax};
			print "$_[1]->{address}\n\n";
			return; # the <person> tag is processed, no need to remember what it contained
		},
	]
);

$parser->parsestring($xml);
