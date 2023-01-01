#!perl
#
# see the README file for how to build this module

use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Test2::Tools::Command',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Test2/Tools/Command.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'File::Spec'    => '0', 'Test2::V0' => '0', },
    requires           => {
        'perl'        => '5.10.0',
        'File::chdir' => '0',
        'IPC::Open3'  => '0',
        'Symbol'      => '0',
        'Test2::V0'   => '0',
    },
    sign           => 1,
    add_to_cleanup => ['Test2-Tools-Command-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge => {
        resources => { repository => 'https://thrig.me/src/Test2-Tools-Command.git' }
    },
);

$builder->create_build_script();
