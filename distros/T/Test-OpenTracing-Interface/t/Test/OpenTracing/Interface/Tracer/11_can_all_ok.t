use Test::More;

use Test::OpenTracing::Interface::Tracer;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'Tracer',
    interface_methods => [
        'extract_context',
        'get_active_span',
        'get_scope_manager',
        'inject_context',
        'start_active_span',
        'start_span',
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::Tracer;

sub extract_context;
sub get_active_span;
sub get_scope_manager;
sub inject_context;
sub start_active_span;
sub start_span;

1;
