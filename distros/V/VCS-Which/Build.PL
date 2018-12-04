use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'VCS::Which',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/VCS/Which.pm',
    requires          => {
        perl                 => 5.010,
        'Contextual::Return' => 0,
        'File::chdir'        => 0,
        'IO::Prompt'         => 0,
        'List::MoreUtils'    => 0,
        'List::Util'         => 0,
        'Moo'                => 0,
        'Path::Tiny'         => 0,
        'version'            => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::Fatal'          => 0,
        'Test::More'           => '0.88',
        'Test::Warnings'       => '0.026',
        'Test::MinimumVersion' => 0,
    },
    recommends => {
        'Time::HiRes' => 0,
    },
    add_to_cleanup     => [ 'VCS-Which-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/ivanwills/VCS-Which',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=VCS-Which',
        },
    },
);

$builder->create_build_script();
