use 5.012000;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'Web::MREST::CLI',
    license              => 'bsd',
    dist_author          => q{Nathan Cutler <ncutler@suse.cz>},
    dist_version_from    => 'lib/Web/MREST/CLI.pm',
    create_license       => 0,
    create_readme        => 0,
    release_status       => 'stable',
    share_dir            => {
        dist => [ 'config' ],
    },
    meta_merge => {
        no_index => {
            directory => [
                "config"
            ]
        }
    },
    script_files         => [
        'bin/mrest-cli',
    ],
    configure_requires => {
        'Module::Build'  => 0,
    },
    build_requires => {
        'File::Basename' => 0,
        'File::HomeDir'  => 0,
    },
    requires => {
        'perl'           => 5.012,
        'App::CELL'      => 0.205,
        'Data::Dumper'   => 0,
        'Encode'         => 0,
        'File::HomeDir'  => 0,
        'File::ShareDir' => 0,
        'Getopt::Long'   => 2.32,
        'HTTP::Request::Common'  => 0,
        'JSON'           => 0,
        'Log::Any::Adapter' => 0,
        'LWP::UserAgent' => 6.05,
        'LWP::Protocol::https' => 6.04,
        'Params::Validate' => 0,
        'Pod::Usage'     => 0,
        'Term::ReadLine' => 0,
        'Test::Deep'     => 0,
        'Try::Tiny'      => 0,
        'URI::Escape'    => 0,
    },
    add_to_cleanup     => [ 'Web-MREST-CLI-*' ],
#    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
);

$builder->create_build_script();
