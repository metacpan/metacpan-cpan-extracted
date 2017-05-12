use strict;
use warnings;
use Encode;
use Test::More tests => 6;

use_ok ('XML::FOAFKnows::FromvCard');


my $data = <<'_EOD_';
BEGIN:VCARD
CLASS:PUBLIC
EMAIL:blueberry.jam@example.invalid
FN:Blåbærsyltetøy
N:Syltetøy;Blåbær;;;
UID:yiLst2xaHn
VERSION:3.0
END:VCARD

_EOD_


my $docexpected = <<'_EOD_';
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:foaf="http://xmlns.com/foaf/0.1/">
<foaf:Person rdf:about="http://search.cpan.org/~kjetilk/#fictious">
	<foaf:mbox_sha1sum>118e4bc7a8668b31b71e2b53173e627b66fe8f62</foaf:mbox_sha1sum>
	<rdfs:seeAlso rdf:resource="http://www.kjetil.kjernsmo.net/foaf.rdf"/>

<foaf:knows>
	<foaf:Person rdf:nodeID="person1">
		<foaf:mbox_sha1sum>b77984ffe607a1a82abd4e3ae962ce35b7fbf938</foaf:mbox_sha1sum>
		<foaf:family_name>Syltetøy</foaf:family_name>
		<foaf:givenname>Blåbær</foaf:givenname>
		<foaf:name>Blåbær Syltetøy</foaf:name>
	</foaf:Person>
</foaf:knows>

</foaf:Person>
</rdf:RDF>
_EOD_

ok(my $text = XML::FOAFKnows::FromvCard->format(decode_utf8($data,
							    Encode::FB_XMLCREF),
						(uri => 'http://search.cpan.org/~kjetilk/#fictious', 
						 seeAlso => 'http://www.kjetil.kjernsmo.net/foaf.rdf', 
						 email => 'kjetilk@cpan.org')), "Constructing object");

isa_ok( $text, 'XML::FOAFKnows::FromvCard' );

ok(my $out = $text->document('UTF-8'), 'Assignment OK');

ok(my $encoded = encode_utf8($out), 'Encoding to UTF8');

ok($encoded eq $docexpected, 'Document comes out with correctly encoded UTF8 as expected');


open (FILE, "> /tmp/data");
print FILE $encoded;
close FILE;
