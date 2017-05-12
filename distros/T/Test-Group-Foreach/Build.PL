use 5.006001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Test::Group::Foreach',
    dist_author => 'Nick Cleaton <nick@cleaton.net>',
    all_from    => 'lib/Test/Group/Foreach.pm',
    license     => 'perl',
    requires    => {
        'perl'               => 5.006001,
        'Test::NameNote'     => 0,
        'Test::Group'        => 0.16,
    },
    build_requires => {
        'Pod::Snippets'         => 0,
        'Test::Builder::Tester' => 0,
        'Test::Exception'       => 0,
        'Test::More'            => 0,
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
