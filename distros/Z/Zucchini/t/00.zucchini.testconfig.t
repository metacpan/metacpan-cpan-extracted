#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::NoWarnings;
use Test::More tests => 12;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/lib};
}

BEGIN {
    use_ok 'Zucchini::TestConfig';
}

# evil globals
my ($test_config);

# get a test_config object
$test_config = Zucchini::TestConfig->new();

# make sure it's the right thingy
isa_ok($test_config, q{Zucchini::TestConfig});

# make sure we can call expected methods
can_ok(
    $test_config,
    qw<
        get_testdir
        set_testdir
        get_templatedir
        set_templatedir
        get_includedir
        set_includedir
        get_outputdir
        set_outputdir
        get_rsyncpath
        set_rsyncpath
        get_config
        set_config
    >
);

# make sure that "special" variables are set, and not XXWILLBEOVERRIDDENXX
# value still
my $value;

$value = $test_config->get_templatedir;
isnt($value, q{XXWILLBEOVERRIDDENXX}, q{get_templatedir value is sane});
ok(-d $value, q{templatedir exists});

$value = $test_config->get_includedir;
isnt($value, q{XXWILLBEOVERRIDDENXX}, q{get_includedir value is sane});
ok(-d $value, q{includedir exists});

$value = $test_config->get_outputdir;
isnt($value, q{XXWILLBEOVERRIDDENXX}, q{get_outputdir value is sane});
ok(-d $value, q{outputdir exists});

$value = $test_config->get_rsyncpath;
isnt($value, q{XXWILLBEOVERRIDDENXX}, q{get_rsyncpath value is sane});
ok(-d $value, q{rsyncpath exists});
