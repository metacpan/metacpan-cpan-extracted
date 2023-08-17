use Test::More;

use Test::OpenTracing::Interface::ScopeManager;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'ScopeManager',
    interface_methods => [
        'activate_span',
        'get_active_scope'
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::ScopeManager;

sub activate_span;
sub get_active_scope;

1;
