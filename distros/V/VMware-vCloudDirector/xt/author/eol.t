use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/VMware/vCloudDirector.pm',
    'lib/VMware/vCloudDirector/API.pm',
    'lib/VMware/vCloudDirector/Error.pm',
    'lib/VMware/vCloudDirector/Link.pm',
    'lib/VMware/vCloudDirector/Object.pm',
    'lib/VMware/vCloudDirector/ObjectContent.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
