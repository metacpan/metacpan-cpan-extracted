use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::UniqueTestNames',
    license             => 'perl',
    dist_author         => 'Josh Heumann <cpan@joshheumann.com>',
    dist_version_from   => 'lib/Test/UniqueTestNames.pm',
    build_requires => {
        'Hook::LexWrap'    => 0,
        'Test::Builder'    => 0,
        'Test::Exception'  => 0,
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
    },
    add_to_cleanup     => [ 'Test-UniqueTestNames-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
