use Test::Most;
use Test::OpenTracing::Interface::SpanContext qw/can_all_ok/;

use strict;
use warnings;

use OpenTracing::Implementation::Test::SpanContext;

can_all_ok('OpenTracing::Implementation::Test::SpanContext');

done_testing();
