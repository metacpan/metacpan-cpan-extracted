use v5.14;
use warnings;
use Module::Build;


my $build = Module::Build->new(
    module_name       => 'UAV::Pilot::WumpusRover',
    dist_abstract     => 'UAV::Pilot driver for the WumpusRover',
    dist_author       => q{Timm Murray <tmurray@wumpus-cave.net>},
    dist_version_from => 'lib/UAV/Pilot/WumpusRover.pm',
    license           => 'bsd',
    requires          => {
        perl                   => '>= 5.14.0',
        'namespace::autoclean' => 0,
        'AnyEvent'             => 0,
        'Digest::Adler32::XS'  => 0,
        'Moose'                => 0,
        'MooseX::Event'        => 0,
        'Test::More'           => 0,
        'Tie::IxHash'          => 0,
        'UAV::Pilot'           => '>= 0.9',
    },
    test_requires => {
        'Test::Pod' => 0,
    },
    recommends => {
        'Getopt::Long'              => 0,
        'UAV::Pilot::SDL'           => 0,
        'UAV::Pilot::Video::Ffmpeg' => 0,
    },
    share_dir => 'share',

    meta_merge => {
        resources => {
            repository => 'https://github.com/frezik/UAV-Pilot-WumpusRover',
        },
    },
);

$build->create_build_script;
