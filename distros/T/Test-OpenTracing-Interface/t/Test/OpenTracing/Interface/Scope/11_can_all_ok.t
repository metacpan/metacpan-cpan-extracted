use Test::More;

use Test::OpenTracing::Interface::Scope;

use lib 't/lib/';
use Test::OpenTracing::Tester::CanAll;

my $Test = Test::OpenTracing::Tester::CanAll->new(
    interface_name => 'Scope',
    interface_methods => [
        'close',
        'get_span',
    ],
);

$Test->run_tests_can_all_ok;

done_testing();



package MyTest::Scope;

sub close;
sub get_span;

1;
