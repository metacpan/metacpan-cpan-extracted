use Test2::V0;

use File::Find;
use FindBin qw( $Bin );
use Storable qw( retrieve );

my @mocked_tests;
find(\&wanted, "$Bin/../t");
sub wanted { push @mocked_tests, $File::Find::name if /-lwp-mock.out/; }

is \@mocked_tests, bag {
        item match qr/chart.t/;

        all_items match qr/-lwp-mock.out$/;
        end();
    }, 'Found all mocked tests';

for my $test_file ( @mocked_tests ) {
    my $test_name = $test_file =~ s{.*\.\./t}{t}r;
    $test_name =~ s/-lwp-mock.out//;

    ok my $recorded_tests = retrieve( $test_file ), $test_name . ' is a Storable object';

    ok exists $recorded_tests->[0]{response}, 'Mocks recorded for '. $test_name;

    # unrecorded tests consist of qr/^pst0/
}

done_testing;
