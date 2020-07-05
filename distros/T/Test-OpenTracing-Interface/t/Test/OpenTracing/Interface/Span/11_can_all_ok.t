use Test::Most;

use Test::OpenTracing::Interface::Span;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'Span',
    interface_methods => [
        'add_baggage_item',
        'add_baggage_items',
        'add_tag',
        'add_tags',
        'finish',
        'get_baggage_item',
        'get_baggage_items',
        'get_context',
        'get_tags',
        'log_data',
        'overwrite_operation_name',
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::Span;

sub add_baggage_item;
sub add_baggage_items;
sub add_tag;
sub add_tags;
sub finish;
sub get_baggage_item;
sub get_baggage_items;
sub get_context;
sub get_tags;
sub log_data;
sub overwrite_operation_name;

1;
