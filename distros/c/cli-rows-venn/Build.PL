use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'cli::rows::venn',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/cli/rows/venn.pm',
    release_status      => 'stable',
    script_files        => [qw[scripts/venn2 scripts/venn3 scripts/venn4]],
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
    },
    requires => {
        'List::Compare'    => '0.53' , 
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'cli-rows-venn-*' ],
);

$builder->create_build_script();
