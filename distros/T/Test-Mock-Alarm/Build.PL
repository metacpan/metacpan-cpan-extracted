#!/usr/bin/env perl

use Module::Build;

Module::Build->new(
    module_name        => 'Test::Mock::Alarm',
    license            => 'perl',
    dist_abstract      => 'Mock perl\'s built-in alarm function',
    dist_author        => 'Jeremy Jack <jeremy@rocketscientry.com>',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    build_requires     => {
        'Test::More'      => '0',
        'Test::Exception' => '0',
    },
)->create_build_script();
