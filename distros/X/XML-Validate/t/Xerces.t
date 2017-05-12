#!/usr/local/bin/perl

#
# unit test for XML::Validate::Xerces
#

use strict;
use Test::Assertions qw(test);
use Getopt::Std;
use Cwd;

#Due to warning about INIT block not being run in XML::Xerces
BEGIN {$^W = 0}

use vars qw($opt_t $opt_T);
getopts("tT");

my $num_tests = plan tests => 25;

eval {
	require XML::Xerces;
};
if($@) {
	for (1 .. $num_tests) {
		ignore($_);
		ASSERT(1, "XML::Xerces not available");
	}
	exit;
}

chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "../lib";

require XML::Validate::Xerces;
ASSERT(1, "compiled version $XML::Validate::Xerces::VERSION");

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

# Construct validator
my $loose_validator = new XML::Validate::Xerces(strict_validation => 0);
DUMP("the Xerces validator object", $loose_validator);
ASSERT(ref($loose_validator) eq 'XML::Validate::Xerces', "Instantiated a new XML::Validate::Xerces");

ASSERT($loose_validator->version =~ /^[\d.-]+$/, "XML::Xerces version: " . $loose_validator->version);

# Fail to construct with bad opts
eval {
	my $bad_validator = new XML::Validate::Xerces(Foo => 'bar');
};
ASSERT(scalar($@ =~ /Unknown option: Foo/),'Bad options rejected');

# Check Well-formedness of XML
ASSERT($loose_validator->validate($wellformed_XML), 'Well-formed XML checked');
DUMP("Well-formed XML error",$loose_validator->last_error);
ASSERT(!$loose_validator->last_error, 'Well-formed XML leaves no error');

# invalid XML fails and returns an error record
ASSERT(!$loose_validator->validate($malformed_XML), 'malformed XML checked');
DUMP("Malformed XML error",$loose_validator->last_error);
ASSERT(scalar($loose_validator->last_error->{message} =~ /Expected end of tag 'name'/), 'Malformed XML leaves an error');

# Check validity of XML
my $validator = new XML::Validate::Xerces();
$validator->validate($valid_XML);
my $dom = $validator->last_dom();
ASSERT(UNIVERSAL::isa($dom, 'XML::Xerces::DOMDocument'),'Valid XML parsed');
ASSERT(!$validator->last_error, 'Valid XML leaves no error');

# invalid XML fails and returns an error record
ASSERT(!$validator->validate($invalid_XML), 'Invalid XML validity checked');
DUMP("Invalid XML error", $validator->last_error);
ASSERT(scalar($validator->last_error->{message} =~ /Unknown element 'fish'/), 'Invalid XML leaves an error');

# invalid XML with a schema fails and returns an error record
ASSERT(!$validator->validate($invalid_XML_schema), 'Invalid XML with a schema validity checked');
DUMP("Invalid XML error", $validator->last_error);
ASSERT(scalar($validator->last_error->{message} =~ /Unknown element 'fish'/), 'Invalid XML with a schema leaves an error');

# Assert we can use the documentElement on the DOM object
$validator->validate($valid_XML);
my $DOM = $validator->last_dom();
ASSERT($DOM->getDocumentElement(), "Returned DOM can call getDocumentElement method");

# Validate against external entities
$validator->validate($valid_XML_externalDTD);
my $dom = $validator->last_dom();
ASSERT(UNIVERSAL::isa($dom, 'XML::Xerces::DOMDocument'),'Valid XML parsed on external');
ASSERT(!$validator->last_error, 'Valid XML with external DTD leaves no error');
ASSERT(!$validator->validate($invalid_XML_externalDTD),'Invalid XML parsed on external');
DUMP("Invalid XML error", $validator->last_error);
ASSERT(scalar($validator->last_error->{message} =~ /Unknown element 'fish'/), 'Invalid XML with external DTD leaves an error');

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
ASSERT(scalar($@ =~ /validate called with no data/), 'Undefined XML is fatal exception');
eval { $validator->validate("") };
ASSERT(scalar($@ =~ /validate called with no data/), 'Null string XML is fatal exception');

# base_uri option
my $base = cwd().("/foo/base-uri.xml");
$base = "/".$base unless($base =~ "^/"); #Ensure filepath starts with a slash (e.g. win32 drive letter)
$base =~ s/:/%3A/; #Escape colons from Win32 drive letters

my $base_uri_validator = new XML::Validate::Xerces(base_uri => "file://".$base);
TRACE("Using base_uri: $base");
ASSERT($base_uri_validator->validate($base_uri_XML), 'XML checked with different base URI');
DUMP("Base URI error", $base_uri_validator->last_error);

sub TRACE {}
sub DUMP {}
