use strict;
use warnings;

use WWW::Splunk::XMLParser;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Splunk::XMLParser::VERSION, 2.08, 'Version.');
