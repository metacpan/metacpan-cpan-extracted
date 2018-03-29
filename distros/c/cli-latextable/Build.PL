use 5.014;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'cli::latextable',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/cli/latextable.pm',
    release_status      => 'stable',
    script_files        => [qw[scripts/latextable]],
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'cli-latextable-*' ],
);

$builder->create_build_script();
