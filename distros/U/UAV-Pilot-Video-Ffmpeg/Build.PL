use v5.14;
use warnings;
use Module::Build;


my @build_flags = (
    '-Wall',
    scalar( `pkg-config --cflags libavcodec libswscale` ),
);
my @link_flags = (
    scalar( `pkg-config --libs libavcodec libswscale` ),
);


my $build = Module::Build->new(
    module_name       => 'UAV::Pilot::Video::Ffmpeg',
    dist_abstract     => 'Decode UAV video streams in real-time',
    dist_author       => q{Timm Murray <tmurray@wumpus-cave.net>},
    dist_version_from => 'lib/UAV/Pilot/Video/Ffmpeg.pm',
    license           => 'bsd',
    needs_compiler    => 1,
    build_requires    => {
        'ExtUtils::CBuilder' => 0,
    },
    requires          => {
        perl                   => '>= 5.14.0',
        'namespace::autoclean' => 0,
        #'Alien::ffmpeg'        => 0,
        'Moose'                => 0,
        'Test::More'           => 0,
        'UAV::Pilot'           => '1.3',
        'XSLoader'             => 0,
    },

    include_dirs         => ['.'],
    dynamic_config       => 1,
    allow_pureperl       => 0,
    extra_compiler_flags => join( ' ', @build_flags ),
    extra_linker_flags   => join( ' ', @link_flags ),
    meta_merge => {
        resources => {
            repository => 'https://github.com/frezik/UAV-Pilot-Video-Ffmpeg',
        },
    },
);

$build->create_build_script;
