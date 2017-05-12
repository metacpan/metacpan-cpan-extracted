#!/usr/local/bin/perl -w

#
# unit test for XML::Validate::MSXML
#

use strict;
use Test::Assertions qw(test);
use Getopt::Std;

use vars qw($opt_t $opt_T);
getopts("tT");

my $num_tests = plan tests => 24;

chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "../lib";

unless ($^O =~ /^MSWin32$/ && have_dependencies()) 
{
	for (1.. $num_tests) {
		ignore($_);
		ASSERT(1, "MSXML not available");
	}
	exit
}
require XML::Validate::MSXML;
ASSERT(1, "compiled version $XML::Validate::MSXML::VERSION");

# Log::Trace
if($opt_t) { require Log::Trace; import Log::Trace qw(print); }
if($opt_T) { require Log::Trace; deep_import Log::Trace qw(print); }

my $wellformed_XML = READ_FILE("well-formed.xml");
my $malformed_XML = READ_FILE("malformed.xml");
my $valid_XML = READ_FILE("valid.xml");
my $invalid_XML = READ_FILE("invalid.xml");
my $valid_XML_externalDTD = READ_FILE("valid-ext-dtd.xml");
my $invalid_XML_externalDTD = READ_FILE("invalid-ext-dtd.xml");
my $invalid_XML_schema = READ_FILE("invalid-schema.xml");
my $valid_XML_schema = READ_FILE("valid-schema.xml");

# Construct validator
my $loose_validator = new XML::Validate::MSXML(strict_validation => 0);
DUMP("the MSXML validator object", $loose_validator);
ASSERT(ref($loose_validator) eq 'XML::Validate::MSXML', "Instantiated a new XML::Validate::MSXML");

ASSERT($loose_validator->version =~ /^[\d.-]+$/, "MSXML version: " . $loose_validator->version);

# Fail to construct with bad opts
eval {
	my $bad_validator = new XML::Validate::MSXML(Foo => 'bar');
};
ASSERT(scalar($@ =~ /Unknown option: Foo/),'Bad options rejected');

# Check Well-formedness of XML
ASSERT($loose_validator->validate($wellformed_XML), 'Well-formed XML checked');
ASSERT(!$loose_validator->last_error, 'Well-formed XML leaves no error');

# invalid XML fails and returns an error record
ASSERT(!$loose_validator->validate($malformed_XML), 'malformed XML checked');
DUMP("Malformed XML error",$loose_validator->last_error);
ASSERT(scalar($loose_validator->last_error->{message} =~ /End tag 'flower' does not match the start tag 'name'/), 'Malformed XML leaves an error');

# Check validity of XML
my $validator = new XML::Validate::MSXML();
$validator->validate($valid_XML);
my $dom = $validator->last_dom();
DUMP("DOM Document type",Win32::OLE->QueryObjectType($dom));
ASSERT(Win32::OLE->QueryObjectType($dom) =~ m/^IXMLDOMDocument\d+/,'Valid XML parsed');
ASSERT(!$validator->last_error, 'Valid XML leaves no error');

# invalid XML fails an exception and returns an error record
ASSERT(!$validator->validate($invalid_XML), 'Invalid XML validity checked');
DUMP("Invalid XML error", $validator->last_error);
ASSERT(scalar($validator->last_error->{message} =~ /Expecting: plant/), 'Invalid XML leaves an error');

# invalid XML with a schema fails and returns an error record
ASSERT(!$validator->validate($invalid_XML_schema), 'Invalid XML with a schema validity checked');
DUMP("Invalid XML error", $validator->last_error);
ASSERT(scalar($validator->last_error->{message} =~ /Expecting: plant/), 'Invalid XML with a schema leaves an error');

# Assert we can use the documentElement on the DOM object
$validator->validate($valid_XML);
my $DOM = $validator->last_dom();
ASSERT($DOM->documentElement(), "Returned DOM can call documentElement method");

# Validate against external entities
ASSERT(Win32::OLE->QueryObjectType($DOM) =~ m/^IXMLDOMDocument\d+/,'Valid XML parsed on external');
ASSERT(!$validator->last_error, 'Valid XML with external DTD leaves no error');
ASSERT(!$validator->validate($invalid_XML_externalDTD),'Invalid XML parsed on external');
DUMP("Invalid XML error", $validator->last_error);
ASSERT(scalar($validator->last_error->{message} =~ /Expecting: plant/), 'Invalid XML with external DTD leaves an error');

# Assert we can use the documentElement on the DOM object
$validator->validate($valid_XML_externalDTD);
my $DOM_externalDTD = $validator->last_dom();
ASSERT($DOM_externalDTD->documentElement(), "Returned DOM can call documentElement method");

# Assert that well-formed docs with no schema or dtd are considered valid
ASSERT($validator->validate($wellformed_XML), 'Well-formed XML checked with strict validator');

# Assert that valid docs with just a schema are considered valid
ASSERT($validator->validate($valid_XML_schema), 'Valid XML with a schema checked');

# Check errors are reported...
eval { $validator->validate() };
ASSERT(scalar($@ =~ /validate called with no data/), 'Undefined XML is fatal exception');
eval { $validator->validate("") };
ASSERT(scalar($@ =~ /validate called with no data/), 'Null string XML is fatal exception');

sub TRACE {}
sub DUMP {}

#
# This is a bit nasty in that it duplicates code in the module
#
sub have_dependencies {
	eval {
		require Win32::OLE;
		my $warn_level = Win32::OLE->Option('Warn');
		Win32::OLE->Option(Warn => 0);
	
		my($doc, $cache);
		foreach my $version ('5.0', '4.0') {
			$doc   = Win32::OLE->new('MSXML2.DOMDocument.' . $version) or next;
			$cache = Win32::OLE->new('MSXML2.XMLSchemaCache.' . $version) or next;
		}
		
		Win32::OLE->Option(Warn => $warn_level);		
		die unless($doc && $cache);
	};
	return (!$@);
}
