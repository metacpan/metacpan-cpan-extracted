use Test::Most;
use Test::OpenTracing::Interface::Span qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::Test::Span;

can_all_ok('OpenTracing::Implementation::Test::Span');

done_testing();
