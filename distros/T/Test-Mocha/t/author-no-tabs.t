
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Mocha.pm',                  'lib/Test/Mocha/CalledOk.pm',
    'lib/Test/Mocha/CalledOk/AtLeast.pm', 'lib/Test/Mocha/CalledOk/AtMost.pm',
    'lib/Test/Mocha/CalledOk/Between.pm', 'lib/Test/Mocha/CalledOk/Times.pm',
    'lib/Test/Mocha/Method.pm',           'lib/Test/Mocha/MethodCall.pm',
    'lib/Test/Mocha/MethodStub.pm',       'lib/Test/Mocha/Mock.pm',
    'lib/Test/Mocha/Spy.pm',              'lib/Test/Mocha/SpyBase.pm',
    'lib/Test/Mocha/Types.pm',            'lib/Test/Mocha/Util.pm',
    't/author-critic.t',                  't/author-no-tabs.t',
    't/author-pod-syntax.t',              't/called_ok.t',
    't/class_mock.t',                     't/clear.t',
    't/inspect.t',                        't/inspect_all.t',
    't/lib/MyNonThrowable.pm',            't/lib/MyThrowable.pm',
    't/lib/TestClass.pm',                 't/matcher_moose.t',
    't/matcher_typetiny.t',               't/mock.t',
    't/mock_universal.t',                 't/namespace.t',
    't/release-pod-coverage.t',           't/smartmatch.t',
    't/spy.t',                            't/spy_universal.t',
    't/stub.t'
);

notabs_ok($_) foreach @files;
done_testing;
