use 5.010;
use warnings;

use Module::Build;
use lib 'lib';
use Unicorn::Manager::Version;
use Getopt::Long qw(:config pass_through);

my $install      = 0;
my $dist         = 0;
my $meta         = 0;
my @script_files = grep { -f and !-d } glob 'script/*';
my $v            = Unicorn::Manager::Version->new;

GetOptions(
    'install' => \$install,
    'dist'    => \$dist,
    'meta'    => \$meta,
);

my $build = Module::Build->new(
    module_name       => 'Unicorn::Manager',
    dist_abstract     => 'A Perl interface to the Unicorn webserver',
    dist_author       => 'Mugen Kenichi <mugen.kenichi@uninets.eu>',
    dist_version_from => 'lib/Unicorn/Manager/Version.pm',
    license           => 'mit',

    configure_requires => { 'Module::Build' => 0.38, },

    requires => {
        'autodie'               => 0,
        'Test::More'            => 0,
        'Moo'                   => 0,
        'File::Basename'        => 0,
        'YAML'                  => 0,
        'JSON'                  => 0,
        'Carp'                  => 0,
        'Getopt::Long'          => 0,
        'indirect'              => 0,
        'multidimensional'      => 0,
        'B::Hooks::OP::Check'   => 0.19,    # dependency for multidimensional
        'Time::HiRes'           => 0,
        'bareword::filehandles' => 0,
        'Cwd'                   => 0,
        'Proc::Daemon'          => 0,
        'Net::Server::PreFork'  => 0,
        'Net::Interface'        => 0,
        'IO::Socket'            => 0,
    },

    build_requires => { 'Module::Build' => 0.38, },

    script_files => [@script_files],

    add_to_cleanup => ['Unicorn-Manager-* Build _build MYMETA.*'],

    meta_add => {
        no_index       => { directory => ['t'], },
        version        => $v->get,
        release_status => 'unstable',
    },

    meta_merge => {
        resources => {
            repository => 'https://github.com/mugenken/Unicorn'
        },
        provides => {
            'Unicorn::Manager' => {
                file    => 'lib/Unicorn/Manager.pm',
                version => $v->get,
            },
            'Unicorn::Manager::CLI' => {
                file    => 'lib/Unicorn/Manager/CLI.pm',
                version => $v->get,
            },
            'Unicorn::Manager::CLI::Proc' => {
                file    => 'lib/Unicorn/Manager/CLI/Proc.pm',
                version => $v->get,
            },
            'Unicorn::Manager::Types' => {
                file    => 'lib/Unicorn/Manager/Types.pm',
                version => $v->get,
            },
            'Unicorn::Manager::Version' => {
                file    => 'lib/Unicorn/Manager/Version.pm',
                version => $v->get,
            },
            'Unicorn::Manager::Server' => {
                file    => 'lib/Unicorn/Manager/Server.pm',
                version => $v->get,
            },
        },
    },
);

if ($meta) {
    $build->dispatch('distmeta');
    exit 0;
}

if ($dist) {
    $build->dispatch('build');
    $build->dispatch('test');
    $build->dispatch('distmeta');
    $build->dispatch('dist');
    $build->create_build_script();
    exit 0;
}

if ($install) {
    $build->dispatch('build');
    $build->dispatch( 'test', verbose => 1 );
    $build->dispatch('install');
    $build->create_build_script();
    exit 0;
}

$build->create_build_script();

