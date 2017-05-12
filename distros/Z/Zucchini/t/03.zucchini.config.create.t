#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok 'Zucchini::Config::Create';
}
BEGIN {
    use File::Temp qw(tempdir);
    use Path::Class;
}

can_ok(
    'Zucchini::Config::Create',
    qw(
        new
        write_default_config
    )
);

my $zucchini_cfg_create = Zucchini::Config::Create->new();
isa_ok($zucchini_cfg_create, q{Zucchini::Config::Create});

my $tempdir = tempdir( CLEANUP => 1 );

$zucchini_cfg_create->write_default_config(
    file($tempdir, q{.zucchini})
);
