#!/usr/local/bin/perl -w

#
# unit test for XML::Validate::LibXML
#

use strict;
use Test::Assertions qw(test);
use Getopt::Std;
use Cwd;

use vars qw($opt_t $opt_T);
getopts("tT");

my $num_tests = plan tests => 25;

eval {
	require XML::LibXML;
};
if($@) {
	for (1 .. $num_tests) {
		ignore($_);
		ASSERT(1, "XML::LibXML not available");
	}
	exit;
}


chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "../lib";

require XML::Validate::LibXML;
ASSERT(1, "compiled version $XML::Validate::LibXML::VERSION");

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
my $base_uri_XML = READ_FILE("base-uri.xml");
my $valid_XML_schema = READ_FILE("valid-schema.xml");

# Construct loose validator
my $loose_validator = new XML::Validate::LibXML(strict_validation => 0);
DUMP("the LibXML validator object", $loose_validator);
ASSERT(ref($loose_validator) eq 'XML::Validate::LibXML', "Instantiated a new XML::Validate::LibXML");

ASSERT($loose_validator->version =~ /^[\d.-]+$/, "XML::LibXML version: " . $loose_validator->version);

# Fail to construct with bad opts
eval {
	my $bad_validator = new XML::Validate::LibXML(Foo => 'bar');
};
ASSERT(scalar($@ =~ /Unknown option: Foo/),'Bad options rejected');

# Check Well-formedness of XML
ASSERT($loose_validator->validate($wellformed_XML), 'Well-formed XML checked');
ASSERT(!$loose_validator->last_error, 'Well-formed XML leaves no error');

# invalid XML fails and returns an error record
ASSERT(!$loose_validator->validate($malformed_XML), 'malformed XML checked');
DUMP("Malformed XML error",$loose_validator->last_error);
ASSERT($loose_validator->last_error->{message} =~ /Opening and ending tag mismatch/, 'Malformed XML leaves an error');

# Check validity of XML
my $validator = new XML::Validate::LibXML();
$validator->validate($valid_XML);
my $dom = $validator->last_dom();
ASSERT(UNIVERSAL::isa($dom, 'XML::LibXML::Document'),'Valid XML parsed');
ASSERT(!$validator->last_error, 'Valid XML leaves no error');

# invalid XML fails and returns an error record
ASSERT(!$validator->validate($invalid_XML), 'Invalid XML validity checked');
DUMP("Invalid XML error", $validator->last_error);
ASSERT($validator->last_error->{message} =~ /No declaration for element fish/, 'Invalid XML leaves an error');

# invalid XML with a schema fails and returns an error record
# This doesn't work in LibXML. It isn't schema capable. So we ignore for now.
ignore(13);
ASSERT(!$validator->validate($invalid_XML_schema), 'Invalid XML with a schema validity checked');
DUMP("Invalid XML error", $validator->last_error);
ignore(14);
ASSERT($validator->last_error && $validator->last_error->{message} =~ /No declaration for element fish/, 'Invalid XML with a schema leaves an error');

# Assert we can use the documentElement on the DOM object
$validator->validate($valid_XML);
my $DOM = $validator->last_dom();;
ASSERT($DOM->getDocumentElement(), "Returned DOM can call getDocumentElement method");

# Validate against external entities
$validator->validate($valid_XML_externalDTD);
$DOM = $validator->last_dom();;
ASSERT(UNIVERSAL::isa($DOM, 'XML::LibXML::Document'),'Valid XML parsed on external');
ASSERT(!$validator->last_error, 'Valid XML with external DTD leaves no error');
ASSERT(!$validator->validate($invalid_XML_externalDTD),'Invalid XML parsed on external');
DUMP("Invalid XML error", $validator->last_error);
ASSERT($validator->last_error->{message} =~ /No declaration for element fish/, 'Invalid XML with external DTD leaves an error');

# Assert we can use the documentElement on the DOM object
$validator->validate($valid_XML_externalDTD);
my $DOM_externalDTD = $validator->last_dom();
ASSERT($DOM_externalDTD->getDocumentElement(), "Returned DOM can call getDocumentElement method");

# Assert that well-formed docs with no schema or dtd are considered valid
ASSERT($validator->validate($wellformed_XML), 'Well-formed XML checked with strict validator');

# Assert that valid docs with just a schema are considered valid
ASSERT($validator->validate($valid_XML_schema), 'Valid XML with a schema checked');

# Check errors are reported...
eval { $validator->validate() };
ASSERT($@ =~ /validate called with no data/, 'Undefined XML is fatal exception');
eval { $validator->validate("") };
ASSERT($@ =~ /validate called with no data/, 'Null string XML is fatal exception');

# base_uri option
ignore(25); # This is broken in XML::LibXML v1.58
my $base = cwd().("/foo/base-uri.xml");
$base = "/".$base unless($base =~ "^/"); #Ensure filepath starts with a slash (e.g. win32 drive letter)
$base =~ s/:/%3A/; #Escape colons arising from Win32 drive letters
$base = 'file://'.$base;
my $base_uri_validator = new XML::Validate::LibXML(base_uri => $base);
TRACE("Using base_uri: $base");
ASSERT($base_uri_validator->validate($base_uri_XML), 'XML checked with different base URI');
DUMP("Base URI error", $base_uri_validator->last_error);

sub TRACE {}
sub DUMP {}

