use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/VMware/vCloudDirector2.pm',
    'lib/VMware/vCloudDirector2/API.pm',
    'lib/VMware/vCloudDirector2/Error.pm',
    'lib/VMware/vCloudDirector2/Link.pm',
    'lib/VMware/vCloudDirector2/Object.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
