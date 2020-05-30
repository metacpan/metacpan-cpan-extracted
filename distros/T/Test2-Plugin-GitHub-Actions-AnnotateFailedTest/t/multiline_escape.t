use strict;
use warnings;
use Test2::Plugin::GitHub::Actions::AnnotateFailedTest;
use Test2::V0;

is +Test2::Plugin::GitHub::Actions::AnnotateFailedTest::_escape_data("hoge\r\nfuga"), 'hoge%0D%0Afuga';

done_testing;
