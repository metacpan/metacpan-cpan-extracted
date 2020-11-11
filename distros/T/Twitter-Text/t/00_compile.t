use strict;
use Test::More 0.98;
use Test2::Plugin::GitHub::Actions::AnnotateFailedTest;

use_ok $_ for qw(
    Twitter::Text
    Twitter::Text::Configuration
    Twitter::Text::Regexp
    Twitter::Text::Regexp::Emoji
);

done_testing;

