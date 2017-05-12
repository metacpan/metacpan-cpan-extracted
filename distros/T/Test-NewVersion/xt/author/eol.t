use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Test/NewVersion.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/03-pod.t',
    't/04-blib.t',
    't/corpus/basic/META.json',
    't/corpus/basic/lib/Bar/Baz.pm',
    't/corpus/basic/lib/ExtUtils/MakeMaker.pm',
    't/corpus/basic/lib/Foo.pm',
    't/corpus/basic/lib/Moose.pm',
    't/corpus/basic/lib/Moose/Cookbook.pod',
    't/corpus/basic/lib/Plack/Test.pm',
    't/corpus/blib/blib/lib/Bar.pm',
    't/corpus/blib/lib/Bar.pm',
    't/corpus/blib/lib/Foo.pm',
    't/corpus/pod/lib/Bar.pod',
    't/corpus/pod/lib/Foo.pm',
    't/lib/NoNetworkHits.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
