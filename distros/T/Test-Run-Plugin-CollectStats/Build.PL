use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::CollectStats',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/CollectStats.pm',
    configure_requires => { 'Module::Build' => '0.36', },
    build_requires => {
        'Test::More' => 0,
        'Test::Trap' => 0,
    },
    requires => {
        'Moose' => 0,
        'Test::Run::Core' => '0.0106',
        'MRO::Compat' => 0,
        'Storable' => 0,
        'Test::Run::Base::Struct' => 0,
        'perl' => '5.008',
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-CollectStats-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
