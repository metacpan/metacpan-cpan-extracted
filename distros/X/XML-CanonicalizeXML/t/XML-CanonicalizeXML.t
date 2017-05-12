# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CanonicalizeXML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('XML::CanonicalizeXML') };

#########################


my $soapbody=
'<SOAP-ENV:Body
xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/04/utility" Id="myBody">
<Catalog xmlns="http://skyservice.pha.jhu.edu" />
</SOAP-ENV:Body>';

$body_xpath=
'<XPath xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
(//. | //@* | //namespace::*)[ancestor-or-self::SOAP-ENV:Body]
</XPath>';

#$si_xpath=
#'<XPath xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
#(//. | //@* | //namespace::*)[ancestor-or-self::ds:SignedInfo]
#</XPath>';*/

$testresult1=
'<SOAP-ENV:Body xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" Id="myBody">
<Catalog xmlns="http://skyservice.pha.jhu.edu"></Catalog>
</SOAP-ENV:Body>';

$testresult2=
'<SOAP-ENV:Body xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsu="http://schemas.xmlsoap.org/ws/2002/04/utility" Id="myBody">
<Catalog xmlns="http://skyservice.pha.jhu.edu"></Catalog>
</SOAP-ENV:Body>';

$test1=XML::CanonicalizeXML::canonicalize($soapbody, $body_xpath,
"SOAP-ENV", 1, 0);

$test2=XML::CanonicalizeXML::canonicalize($soapbody, $body_xpath,
"SOAP-ENV", 0, 0);

is($test1, $testresult1,	'exclusive canonicalization test');
is($test2, $testresult2,	'inclusive canonicalization test');

