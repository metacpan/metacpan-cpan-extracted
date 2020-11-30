use strict;
use Test::More 0.98;
BEGIN {
    eval {
        require Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
        Test2::Plugin::GitHub::Actions::AnnotateFailedTest->import;
    };
}

use_ok $_ for qw(
    Twitter::Text
    Twitter::Text::Configuration
    Twitter::Text::Regexp
    Twitter::Text::Regexp::Emoji
);

done_testing;

