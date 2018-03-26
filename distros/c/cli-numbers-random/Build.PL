use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'cli::numbers::random',
    license             => 'gpl3',
    dist_author         => q{"Toshiyuki Shimono" <bin4tsv@gmail.com>},
    dist_version_from   => 'lib/cli/numbers/random.pm',
    release_status      => 'stable',
    script_files        => [ qw(scripts/randexp scripts/binom scripts/cauchydist scripts/saikoro scripts/poisson scripts/boxmuller) ],
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
    add_to_cleanup     => [ 'cli-numbers-random-*' ],
);

$builder->create_build_script();
