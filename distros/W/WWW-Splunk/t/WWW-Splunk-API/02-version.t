use strict;
use warnings;

use WWW::Splunk::API;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Splunk::API::VERSION, 2.08, 'Version.');
