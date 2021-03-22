use strict;
use warnings;
use Test::More 0.98;
BEGIN {
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
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

