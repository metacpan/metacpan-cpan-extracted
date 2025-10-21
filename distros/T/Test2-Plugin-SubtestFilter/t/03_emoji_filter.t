use Test2::V0;
use Test2::Plugin::UTF8;

use lib 't/lib';
use TestHelper;

my $test_file = 't/examples/emoji.t';

my @tests = (
    {
        name => 'no SUBTEST_FILTER - all tests run',
        filter => undef,
        expect => {
            '🔥 Performance'                         => 'executed',
            '🔥 Performance > ⚡ Speed tests'        => 'executed',
            '🔥 Performance > 💾 Memory tests'       => 'executed',
            '🐛 Bug fixes'                           => 'executed',
            '🐛 Bug fixes > 🔧 Critical fixes'       => 'executed',
            '✨ Features'                             => 'executed',
            '✨ Features > 🎨 UI improvements'        => 'executed',
            '✨ Features > 🎨 UI improvements > 🌈 Color scheme' => 'executed',
            '📝 Documentation'                       => 'executed',
        },
    },
    {
        name => 'SUBTEST_FILTER=🔥 - matches Performance',
        filter => '🔥',
        expect => {
            '🔥 Performance'                         => 'executed',
            '🔥 Performance > ⚡ Speed tests'        => 'executed',
            '🔥 Performance > 💾 Memory tests'       => 'executed',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'skipped',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER=⚡ - matches Speed tests',
        filter => '⚡',
        expect => {
            '🔥 Performance'                         => 'executed',
            '🔥 Performance > ⚡ Speed tests'        => 'executed',
            '🔥 Performance > 💾 Memory tests'       => 'skipped',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'skipped',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with space-separated emoji path',
        filter => '🔥 Performance ⚡ Speed tests',
        expect => {
            '🔥 Performance'                         => 'executed',
            '🔥 Performance > ⚡ Speed tests'        => 'executed',
            '🔥 Performance > 💾 Memory tests'       => 'skipped',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'skipped',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER for deeply nested emoji 🌈',
        filter => '🌈',
        expect => {
            '🔥 Performance'                         => 'skipped',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'executed',
            '✨ Features > 🎨 UI improvements'        => 'executed',
            '✨ Features > 🎨 UI improvements > 🌈 Color scheme' => 'executed',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER="Critical" - matches text in emoji subtest',
        filter => 'Critical',
        expect => {
            '🔥 Performance'                         => 'skipped',
            '🐛 Bug fixes'                           => 'executed',
            '🐛 Bug fixes > 🔧 Critical fixes'       => 'executed',
            '✨ Features'                             => 'skipped',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with multiple emoji patterns',
        filter => '🔥|🐛',
        expect => {
            '🔥 Performance'                         => 'executed',
            '🔥 Performance > ⚡ Speed tests'        => 'executed',
            '🔥 Performance > 💾 Memory tests'       => 'executed',
            '🐛 Bug fixes'                           => 'executed',
            '🐛 Bug fixes > 🔧 Critical fixes'       => 'executed',
            '✨ Features'                             => 'skipped',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'No match with emoji filter 🎯 - skips all',
        filter => '🎯',
        expect => {
            '🔥 Performance'                         => 'skipped',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'skipped',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with partial text match - Features',
        filter => 'Features',
        expect => {
            '🔥 Performance'                         => 'skipped',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'executed',
            '✨ Features > 🎨 UI improvements'        => 'executed',
            '✨ Features > 🎨 UI improvements > 🌈 Color scheme' => 'executed',
            '📝 Documentation'                       => 'skipped',
        },
    },
    {
        name => 'SUBTEST_FILTER with mixed emoji and text path',
        filter => '✨ Features 🎨 UI',
        expect => {
            '🔥 Performance'                         => 'skipped',
            '🐛 Bug fixes'                           => 'skipped',
            '✨ Features'                             => 'executed',
            '✨ Features > 🎨 UI improvements'        => 'executed',
            '✨ Features > 🎨 UI improvements > 🌈 Color scheme' => 'executed',
            '📝 Documentation'                       => 'skipped',
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
