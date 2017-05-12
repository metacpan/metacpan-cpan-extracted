#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    use_ok 'Zucchini';
}

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/lib};
    use Zucchini::TestConfig;
}

can_ok(
    'Zucchini',
    qw(
        new
        get_config
        set_config
        gogogo
        remote_sync
        ftp_sync
    )
);

# evil globals
my ($test_config, $zucchini);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});

$zucchini = Zucchini->new(
    {
        config_data => $test_config->site_config
    }
);
isa_ok($zucchini, q{Zucchini});
ok(defined($zucchini->get_config), q{object has configuration data});
