
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Fixture/DBIC/Schema.pm',
    't/00-compile.t',
    't/00_compile.t',
    't/01_simple.t',
    't/02_exception.t',
    't/Foo.pm',
    't/Foo/Artist.pm',
    't/Foo/CD.pm',
    't/Foo/ViewAll.pm',
    't/Tools.pm',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/fixture.yaml'
);

notabs_ok($_) foreach @files;
done_testing;
