use v5.14;
use warnings;
use Module::Build;

my @build_flags = (
    '-Wall',
    #'-fPIC',
    scalar( `pkg-config --cflags libavcodec libswscale` ),
    scalar( `sdl-config --cflags` ),
);
my @link_flags = (
    scalar( `pkg-config --libs libavcodec libswscale` ),
    scalar( `sdl-config --libs` ),
);

my $build = Module::Build->new(
    module_name       => 'UAV::Pilot::SDL',
    dist_abstract     => 'SDL Extensions for UAV::Pilot',
    dist_author       => q{Timm Murray <tmurray@wumpus-cave.net>},
    dist_version_from => 'lib/UAV/Pilot/SDL.pm',
    license           => 'bsd',
    needs_compiler    => 0,
    build_requires    => {
        'ExtUtils::CBuilder' => 0, # For FFmpeg; make optional with that
    },
    requires          => {
        perl                        => '>= 5.14.0',
        'namespace::autoclean'      => 0,
        'AnyEvent'                  => 0,
        'Log::Log4perl'             => 0,
        'Moose'                     => 0,
        'MooseX::Event'             => 0,
        'SDL'                       => 0,
        'Test::More'                => 0,
        'Time::HiRes'               => 0,
        'UAV::Pilot'                => '1.1',
    },

    include_dirs         => ['.'],
    dynamic_config       => 1,
    allow_pureperl       => 0,
    extra_compiler_flags => join( ' ', @build_flags ),
    extra_linker_flags   => join( ' ', @link_flags ),

    meta_merge => {
        resources => {
            repository => 'https://github.com/frezik/UAV-Pilot-SDL',
        },
    },
);

$build->create_build_script;
