$|=1;
use XML::Rules;

$xml = <<'*END*';
<doc boo="789">
 <person active="1">
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
 <person active="0">
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
 <some><other>stuff</other></some>
</doc>
*END*

my $parser = new XML::Rules (
	rules => [
		'^bogus' => undef, # means "ignore". The subtags ARE NOT processed.
		_default => 'raw',
		email => 'raw extended',
		person => sub {
			if ($_[1]->{':email'}{_content} =~ /bogus/) {
				return;
			}
			return $_[0] => $_[1];
		},
	],
	style => 'filter'
	# other options
);

$parser->filterstring($xml, \*STDOUT);
