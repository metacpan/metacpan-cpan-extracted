use strict;
use warnings;
use Test::More tests => 20;

use_ok ('XML::FOAFKnows::FromvCard');


my $data = <<'_EOD_';
BEGIN:VCARD
CLASS:PRIVATE
EMAIL:foobar@example.invalid
FN:Foo Bar
N:Bar;Foo;;;
UID:rpyKXuQx9J
URL:http://www.foobar.org/
VERSION:3.0
END:VCARD

BEGIN:VCARD
CLASS:PUBLIC
EMAIL:john.smith@example.invalid
FN:John Smith
N:Smith;John;;;
UID:yiLst2xaHn
URL:http://www.smith.invalid.uk/
VERSION:3.0
END:VCARD

_EOD_

my $fragexpected = <<'_EOD_';
<foaf:knows>
	<foaf:Person rdf:nodeID="person1">
		<foaf:mbox_sha1sum>fd6daac7036c77f48a3803b706e06a963b27de56</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.foobar.org/"/>
	</foaf:Person>
</foaf:knows>
<foaf:knows>
	<foaf:Person rdf:nodeID="person2">
		<foaf:mbox_sha1sum>47d56eaaf12f1686e4d59612507ab42a08c22145</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.smith.invalid.uk/"/>
		<foaf:family_name>Smith</foaf:family_name>
		<foaf:givenname>John</foaf:givenname>
		<foaf:name>John Smith</foaf:name>
	</foaf:Person>
</foaf:knows>
_EOD_
my $onlyprivateexpected = <<'_EOD_';
<foaf:knows>
	<foaf:Person rdf:nodeID="person1">
		<foaf:mbox_sha1sum>fd6daac7036c77f48a3803b706e06a963b27de56</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.foobar.org/"/>
	</foaf:Person>
</foaf:knows>
<foaf:knows>
	<foaf:Person rdf:nodeID="person2">
		<foaf:mbox_sha1sum>47d56eaaf12f1686e4d59612507ab42a08c22145</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.smith.invalid.uk/"/>
	</foaf:Person>
</foaf:knows>
_EOD_

my $publicoverrideexpected = <<'_EOD_';
<foaf:knows>
	<foaf:Person rdf:nodeID="person1">
		<foaf:mbox_sha1sum>fd6daac7036c77f48a3803b706e06a963b27de56</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.foobar.org/"/>
		<foaf:family_name>Bar</foaf:family_name>
		<foaf:givenname>Foo</foaf:givenname>
		<foaf:name>Foo Bar</foaf:name>
	</foaf:Person>
</foaf:knows>
<foaf:knows>
	<foaf:Person rdf:nodeID="person2">
		<foaf:mbox_sha1sum>47d56eaaf12f1686e4d59612507ab42a08c22145</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.smith.invalid.uk/"/>
		<foaf:family_name>Smith</foaf:family_name>
		<foaf:givenname>John</foaf:givenname>
		<foaf:name>John Smith</foaf:name>
	</foaf:Person>
</foaf:knows>
_EOD_


my $docexpected = <<'_EOD_';
<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:foaf="http://xmlns.com/foaf/0.1/">
<foaf:Person rdf:about="http://search.cpan.org/~kjetilk/#fictious">
	<foaf:mbox_sha1sum>118e4bc7a8668b31b71e2b53173e627b66fe8f62</foaf:mbox_sha1sum>
	<rdfs:seeAlso rdf:resource="http://www.kjetil.kjernsmo.net/foaf.rdf"/>

<foaf:knows>
	<foaf:Person rdf:nodeID="person1">
		<foaf:mbox_sha1sum>fd6daac7036c77f48a3803b706e06a963b27de56</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.foobar.org/"/>
	</foaf:Person>
</foaf:knows>
<foaf:knows>
	<foaf:Person rdf:nodeID="person2">
		<foaf:mbox_sha1sum>47d56eaaf12f1686e4d59612507ab42a08c22145</foaf:mbox_sha1sum>
		<foaf:homepage rdf:resource="http://www.smith.invalid.uk/"/>
		<foaf:family_name>Smith</foaf:family_name>
		<foaf:givenname>John</foaf:givenname>
		<foaf:name>John Smith</foaf:name>
	</foaf:Person>
</foaf:knows>

</foaf:Person>
</rdf:RDF>
_EOD_

ok(my $text = XML::FOAFKnows::FromvCard->format($data, 
					     (uri => 'http://search.cpan.org/~kjetilk/#fictious', 
					      seeAlso => 'http://www.kjetil.kjernsmo.net/foaf.rdf', 
					      email => 'kjetilk@cpan.org')), "Constructing object");

isa_ok( $text, 'XML::FOAFKnows::FromvCard' );

ok($text->document eq $docexpected, 'Document comes out as expected');

ok($text->fragment eq $fragexpected, 'Fragment comes out as expected');

ok(my $links = $text->links, 'Assigning links');

my $expectedlinks = [
          {
            'title' => '',
            'url' => 'http://www.foobar.org/'
          },
          {
            'title' => 'John Smith',
            'url' => 'http://www.smith.invalid.uk/'
          }
        ];

ok(eq_array($expectedlinks, $links), 'All links and titles match');


ok(my $text2 = XML::FOAFKnows::FromvCard->format($data, (privacy=>'PRIVATE')),
					  "Constructing for private data");

ok($text2->fragment eq $onlyprivateexpected, 'Only private comes out as expected');

$expectedlinks = [
          {
            'title' => '',
            'url' => 'http://www.foobar.org/'
          },
          {
            'title' => '',
            'url' => 'http://www.smith.invalid.uk/'
          }
        ];

ok(eq_array($expectedlinks, $text2->links), 'All links and titles match for private');

ok(my $text3 = XML::FOAFKnows::FromvCard->format($data, (privacy=>'priVATE')),
					  "Constructing for private data, case insensitive");
ok($text3->fragment eq $onlyprivateexpected, 'Only private comes out as expected, even with confused cases');

ok(my $text4 = XML::FOAFKnows::FromvCard->format($data, (attribute=>'NOFOOATTRIBUTE')),
					  "Constructing with bogus privacy attribute");
ok($text4->fragment eq $onlyprivateexpected, 'Only private comes out as expected, even with bogus attribute parameter');


ok(my $text5 = XML::FOAFKnows::FromvCard->format($data, (privacy=>'PUBLIC')),
					  "Constructing with PUBLIC override");

ok($text5->fragment eq $publicoverrideexpected, 'Everything comes out as expected');

$expectedlinks = [
		  {
		   'title' => 'Foo Bar',
		   'url' => 'http://www.foobar.org/'
		  },
		  {
		   'title' => 'John Smith',
		   'url' => 'http://www.smith.invalid.uk/'
		  }
		 ];

ok(eq_array($expectedlinks, $text5->links), 'All links and titles match for public');

ok(my $text6 = XML::FOAFKnows::FromvCard->format($data, (privacy=>'CONFIDENTIAL')),
					  "Constructing with CONFIDENTIAL");

ok(!$text6->fragment, 'Nothing comes out, as expected');

ok(eq_array([], $text6->links), 'No links returned');

#use Data::Dumper;
#print Dumper($text5->links);

#open (FILE, "> /tmp/data");
#print FILE $text5->fragment;
#close FILE;
