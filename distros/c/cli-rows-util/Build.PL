use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'cli::rows::util',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/cli/rows/util.pm',
    release_status      => 'stable',
    script_files        => [qw[scripts/timeput scripts/expskip scripts/freq scripts/eofcheck scripts/alluniq scripts/idmaker scripts/sampler scripts/shuffler]] , 
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
    add_to_cleanup     => [ 'cli-rows-util-*' ],
);

$builder->create_build_script();
