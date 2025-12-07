use Test2::V0;
use Test2::Require::Module 'Import::Into';

use FindBin qw($Bin);

use lib "$Bin/../../../t/lib";
use TestHelper;

my $test_file = "$Bin/example.pl";

my @tests = (
    {
        name => 'no SUBTEST_FILTER - all tests run',
        filter => undef,
        expect => {
            'foo' => 'executed',
            'bar' => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER=foo - matches foo only',
        filter => 'foo',
        expect => {
            'foo' => 'executed',
            'bar' => 'skipped',
        },
    },
);

for my $tc (@tests) {
    subtest $tc->{name} => sub {
        my $stdout = run_test_file($test_file, $tc->{filter});

        for my $name (sort keys %{$tc->{expect}}) {
            my $status = $tc->{expect}{$name};
            if ($status eq 'executed') {
                like($stdout, match_executed($name), "$name is executed");
            } elsif ($status eq 'skipped') {
                like($stdout, match_skipped($name), "$name is skipped");
            }
        }
    };
}

done_testing;
