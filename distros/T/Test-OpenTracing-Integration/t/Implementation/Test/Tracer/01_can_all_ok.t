use Test::Most;
use Test::OpenTracing::Interface::Tracer qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::Test::Tracer;

can_all_ok('OpenTracing::Implementation::Test::Tracer');

done_testing();
