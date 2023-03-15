use strict;
use warnings;
use utf8;
use PICA::Data qw(pica_parser pica_writer);
use Test::More;

# Make sure we read and write Unicode strings

my $plain = "004J \$a12€\n\n";
my $json  = '[["004J","","a","12€"]]' . "\n";
my $xml   = <<XML;
<record xmlns="info:srw/schema/5/picaXML-v1.0">
  <datafield tag="004J">
    <subfield code="a">12€</subfield>
  </datafield>
</record>
XML

my $rec = pica_parser('plain', $plain)->next;
is $rec->{record}[0][3], '12€', 'PICA Plain from string';

$rec = pica_parser('plain', \$plain)->next;
is $rec->{record}[0][3], '12€', 'PICA Plain from string reference';

$rec = pica_parser('json', $json)->next;
is $rec->{record}[0][3], '12€', 'JSON from string';

$rec = pica_parser('json', \$json)->next;
is $rec->{record}[0][3], '12€', 'JSON from string reference';

$rec = pica_parser('xml', $xml)->next;
is $rec->{record}[0][3], '12€', 'XML from string';

$rec = pica_parser('xml', \$xml)->next;
is $rec->{record}[0][3], '12€', 'XML from string reference';

is $rec->string('plain'), $plain, 'to PICA Plain string';
like $rec->string('xml'), qr/12€/m, 'to XML string';
is $rec->string('json'), $json, 'to JSON string';

done_testing;
