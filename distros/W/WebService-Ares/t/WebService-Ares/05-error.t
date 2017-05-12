# Pragmas.
use strict;
use warnings;

# Modules.
use Test::More 'tests' => 2;
use Test::NoWarnings;
use WebService::Ares;

# Test.
my $obj = WebService::Ares->new;
my $ret = $obj->error;
is($ret, undef, 'Get default error - no error.');
