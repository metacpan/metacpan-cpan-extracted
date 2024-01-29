use strict;
use warnings;

use WWW::Splunk;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($WWW::Splunk::VERSION, 2.09, 'Version.');
