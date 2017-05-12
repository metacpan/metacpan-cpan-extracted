#!perl -T

use strict;
use warnings;
use Test::More tests => 6;

use XML::Rules;

my $xml_plain = <<'*END*';
<doc>
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
 </person>
 <person>
  <fname>John</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
 </person>
</doc>
*END*

my $xml_default = <<'*END*';
<doc xmlns="http://jenda.krynicky.cz/xmlns/test1">
 <person>
  <fname>Jane</fname>
  <lname>Luser</lname>
  <email>JLuser@bogus.com</email>
 </person>
 <person>
  <fname>John</fname>
  <lname>Other</lname>
  <email>JOther@silly.com</email>
 </person>
</doc>
*END*

my $xml_foo = <<'*END*';
<doc xmlns:foo="http://jenda.krynicky.cz/xmlns/test1">
 <foo:person>
  <foo:fname>Jane</foo:fname>
  <foo:lname>Luser</foo:lname>
  <foo:email>JLuser@bogus.com</foo:email>
 </foo:person>
 <foo:person>
  <foo:fname>John</foo:fname>
  <foo:lname>Other</foo:lname>
  <foo:email>JOther@silly.com</foo:email>
 </foo:person>
</doc>
*END*


{ #1 .. 4
	my $parser1 = new XML::Rules (
		rules => [
			_default => 'content',
			person => 'no content array',
			doc => 'no content',
		]
	);
	my $result1 = $parser1->parsestring($xml_plain);

#use Data::Dumper;
#print Dumper($result1);

	my $parser2 = new XML::Rules (
		rules => [
			_default => 'content',
			person => 'no content array',
			doc => 'no content',
		],
		namespaces => {"http://jenda.krynicky.cz/xmlns/test1" => ""},
	);
	my $result2 = $parser2->parsestring($xml_default);
	my $result3 = $parser2->parsestring($xml_foo);

	is_deeply( $result1, $result2, "Plain XML and XML with default namespace mapped to ''");
	is_deeply( $result2, $result3, "XML with default namespace and XML with aliased namespace both mapped to ''");

	my $parser3 = new XML::Rules (
		rules => [
			_default => 'content no xmlns',
			'foo:person' => 'no content array no xmlns',
			doc => 'no content',
			'foo:doc' => 'no content no xmlns',
		],
		namespaces => {"http://jenda.krynicky.cz/xmlns/test1" => "foo"},
	);
	my $result4 = $parser3->parsestring($xml_default);
	my $result5 = $parser3->parsestring($xml_foo);

	is_deeply( $result1, $result4, "Plain XML and XML with default namespace mapped to 'foo', but stripped");
	is_deeply( $result4, $result5, "XML with default namespace and XML with aliased namespace both mapped to 'foo', but stripped");
}

{ # 5 - nesting namespaces

	my $xml = <<"*END*";
<data>
	<first xmlns="http://jenda.krynicky.cz/xmlns/test1">
		<in_first>Hello</in_first>
		<second xmlns="http://jenda.krynicky.cz/xmlns/test2">
			<in_second>Ahoj</in_second>
		</second>
		<back_in_first>Hi</back_in_first>
	</first>
</data>
*END*

	my $parser = new XML::Rules (
		rules => [
			_default => '', # if it ain't got a rule, forget it
			'one:in_first,one:back_in_first' => 'content no xmlns',
			'two:in_second' => 'content no xmlns',
			'two:second' => 'no content no xmlns',
			'one:first' => 'no content no xmlns',
			'data' => 'no content',
		],
		namespaces => {
			"http://jenda.krynicky.cz/xmlns/test1" => "one",
			"http://jenda.krynicky.cz/xmlns/test2" => "two",
		},
	);

	my $result = $parser->parsestring($xml);

#use Data::Dumper;
#print Dumper($result);

	my $correct = {
		'data' => {
			'first' => {
				'back_in_first' => 'Hi',
				'second' => {
					'in_second' => 'Ahoj'
				},
				'in_first' => 'Hello'
			}
		}
	};

	is_deeply( $result, $correct, "XML with nested default namespaces");

	$xml = <<"*END*";
<data>
	<foo:first xmlns:foo="http://jenda.krynicky.cz/xmlns/test1">
		<foo:in_first>Hello</foo:in_first>
		<foo:second xmlns:foo="http://jenda.krynicky.cz/xmlns/test2">
			<foo:in_second>Ahoj</foo:in_second>
		</foo:second>
		<foo:back_in_first>Hi</foo:back_in_first>
	</foo:first>
</data>
*END*

	$result = $parser->parsestring($xml);

use Data::Dumper;
print Dumper($result);

	is_deeply( $result, $correct, "XML with nested aliased namespaces");
}
