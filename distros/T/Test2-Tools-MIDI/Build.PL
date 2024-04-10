#!perl
use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Test2::Tools::MIDI',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@thrig.me>},
    dist_version_from  => 'lib/Test2/Tools/MIDI.pm',
    release_status     => 'stable',
    create_license     => 0,
    create_readme      => 0,
    dynamic_config     => 0,
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      =>
      { 'Test2::V0' => '0.000060', 'Test2::API' => '1.302178' },
    requires => {
        perl        => '5.10.0',
        Carp        => '0',
        'Test2::V0' => '0.000060',
    },
    sign           => 1,
    add_to_cleanup => ['Test2-Tools-MIDI-*'],
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
        resources =>
          { repository => 'https://thrig.me/src/Test2-Tools-MIDI.git' }
    },
);

$builder->create_build_script();
