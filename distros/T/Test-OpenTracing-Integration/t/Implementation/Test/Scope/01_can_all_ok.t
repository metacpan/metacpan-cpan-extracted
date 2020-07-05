use Test::Most;
use Test::OpenTracing::Interface::Scope qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::Test::Scope;

can_all_ok('OpenTracing::Implementation::Test::Scope');

done_testing();
