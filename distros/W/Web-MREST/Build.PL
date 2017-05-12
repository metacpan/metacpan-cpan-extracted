use 5.012000;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name          => 'Web::MREST',
    license              => 'bsd',
    dist_author          => q{Nathan Cutler <ncutler@suse.cz>},
    dist_version_from    => 'lib/Web/MREST.pm',
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
        'bin/mrest',
        'bin/mrest-standalone',
    ],
    configure_requires => {
        'Module::Build'  => 0,
    },
    build_requires => {
        'App::CELL'      => 0.209,
        'Cwd'            => 0,
        'Encode'         => 0,
        'File::Basename' => 0,
        'File::ShareDir' => 0,
        'File::Spec'     => 0,
        'HTTP::Request'  => 0,
        'HTTP::Request::Common'  => 0,
        'JSON'           => 0,
        'LWP::UserAgent' => 6.05,
        'LWP::Protocol::https' => 6.04,
        'Module::Runtime' => 0,
        'Params::Validate' => 0,
        'Path::Router'   => 0.12,
        'Plack'          => 1.0031,
        'Plack::Test'    => 0,
        'Pod::Simple::HTML' => 0,
        'Pod::Simple::Text' => 0,
        'Test::Deep'     => 0,
        'Test::Fatal'    => 0,
        'Test::JSON'     => 0,
        'Test::More'     => 0,
        'Test::Warnings' => 0,
        'Try::Tiny'      => 0,
        'URI::Escape'    => 0,
        'Web::Machine'   => 0.15,
    },
    requires => {
        'perl'           => 5.012,
        'App::CELL'      => 0.205,
        'Getopt::Long'   => 2.32,
        'Encode'         => 0,
        'File::ShareDir' => 0,
        'File::Spec'     => 0,
        'HTTP::Request'  => 0,
        'HTTP::Request::Common'  => 0,
        'JSON'           => 0,
        'LWP::UserAgent' => 6.05,
        'LWP::Protocol::https' => 6.04,
        'Module::Runtime' => 0,
        'Params::Validate' => 1.06,
        'Path::Router'   => 0.12,
        'Plack::Middleware::LogErrors' => 0,
        'Plack::Middleware::Session' => 0,
        'Plack::Middleware::StackTrace' => 0,
        'Plack::Runner'  => 0,
        'Pod::Simple::HTML' => 0,
        'Pod::Simple::Text' => 0,
        'Pod::Usage' => 0,
        'Term::ReadLine' => 0,
        'Test::Deep::NoTest' => 0,
        'Try::Tiny'      => 0,
        'URI::Escape'    => 0,
        'Web::Machine'   => 0.15,
        'Web::MREST::CLI' => 0.276,
    },
    add_to_cleanup     => [ 'Web-MREST-*' ],
#    create_makefile_pl => 'traditional',
    recursive_test_files => 1,
);

$builder->create_build_script();
