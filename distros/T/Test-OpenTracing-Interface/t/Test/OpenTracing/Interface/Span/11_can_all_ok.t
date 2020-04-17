use Test::Most;

use Test::OpenTracing::Interface::Span;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'Span',
    interface_methods => [
        'finish',
        'get_baggage_item',
        'get_context',
        'log_data',
        'overwrite_operation_name',
        'set_baggage_item',
        'set_tag',
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::Span;

sub get_context;
sub overwrite_operation_name;
sub finish;
sub set_tag;
sub log_data;
sub set_baggage_item;
sub get_baggage_item;

1;
