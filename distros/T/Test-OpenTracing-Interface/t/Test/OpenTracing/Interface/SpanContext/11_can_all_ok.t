use Test::Most;

use Test::OpenTracing::Interface::SpanContext;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'SpanContext',
    interface_methods => [
        'with_baggage_item',
        'with_baggage_items',
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::SpanContext;

sub with_baggage_item;
sub with_baggage_items;

1;
