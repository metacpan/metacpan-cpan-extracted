use Test::Most;
use Test::OpenTracing::Interface::ScopeManager qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::Test::ScopeManager;

can_all_ok('OpenTracing::Implementation::Test::ScopeManager');

done_testing();
