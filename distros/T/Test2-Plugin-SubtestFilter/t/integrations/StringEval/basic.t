use Test2::V0;

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

# Test that deeply nested string eval dies with helpful message
# String eval without #line directive creates "(eval N)" file paths.
# When nested too deeply (beyond 4 levels), we cannot find the real file.
subtest 'die when file_path cannot be determined from deep nested string eval' => sub {
    local $ENV{SUBTEST_FILTER} = 'foo';

    my $err;
    eval q{
        eval q{
            eval q{
                eval q{
                    require Test2::Plugin::SubtestFilter;
                    Test2::Plugin::SubtestFilter->import();
                };
                die $@ if $@;
            };
            die $@ if $@;
        };
        $err = $@;
    };

    like($err, qr/Cannot determine file path from eval context/, 'dies with helpful message');
    like($err, qr/apply_plugin/, 'mentions apply_plugin as alternative');
};

done_testing;
