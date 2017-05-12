use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Validate/SPF.pm',
    'lib/Validate/SPF/Parser.pm',
    't/00-compile.t',
    't/01-parser.t',
    't/lib/Parser.pm',
    't/lib/data/mech-a.yaml',
    't/lib/data/mech-all.yaml',
    't/lib/data/mech-exists.yaml',
    't/lib/data/mech-include.yaml',
    't/lib/data/mech-ip4.yaml',
    't/lib/data/mech-ip6.yaml',
    't/lib/data/mech-mx.yaml',
    't/lib/data/mech-ptr.yaml',
    't/lib/data/mod-exp.yaml',
    't/lib/data/mod-redirect.yaml',
    't/lib/data/mod-unknown.yaml',
    't/lib/data/version.yaml',
    't/parser/mech-a.t',
    't/parser/mech-all.t',
    't/parser/mech-exists.t',
    't/parser/mech-include.t',
    't/parser/mech-ip4.t',
    't/parser/mech-ip6.t',
    't/parser/mech-mx.t',
    't/parser/mech-ptr.t',
    't/parser/mod-exp.t',
    't/parser/mod-redirect.t',
    't/parser/mod-unknown.t',
    't/parser/version.t'
);

notabs_ok($_) foreach @files;
done_testing;
