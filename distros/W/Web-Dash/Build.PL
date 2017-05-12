use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Web::Dash',
    license             => 'perl',
    dist_author         => q{Toshio Ito <toshioito@cpan.org>},
    dist_version_from   => 'lib/Web/Dash.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::MockModule' => '0.05',
    },
    requires => {
        'perl' => 5.006,
        'Carp' => 0,
        'Try::Tiny' => 0,
        'Future::Q' => '0.012',
        'Scalar::Util' => '1.20',
        'Net::DBus' => '1.0',
        'AnyEvent::DBus' => '0.31',
        'Encode' => 0,
        'File::Find' => 0,
        'Plack' => 0,
        'Plack::Request' => 0,
        'Plack::Util' => 0,
        'Plack::Runner' => 0,
        'Twiggy' => 0,
        'Try::Tiny' => 0,
        'Async::Queue' => '0.02',
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'JSON' => 0,
    },
    add_to_cleanup      => [ 'Web-Dash-*' ],
    recursive_test_files => 1,
    ## create_makefile_pl => 'traditional',
    no_index    => {
        'directory' => [ 'eg', 'inc', 't', 'xt' ],
        'file' => ['README.pod'],
    },
    meta_add => {
        resources => {
            repository => 'git://github.com/debug-ito/Web-Dash.git',
        },
    },
);

$builder->create_build_script();
