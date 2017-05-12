use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Versionify::Dispatch',
    license             => 'perl',
    dist_author         => 'Glenn Fowler <cebjyre@cpan.org>',
    dist_version_from   => 'lib/Versionify/Dispatch.pm',
    requires => {
        'version'           => 0,
        'Moose'             => 0,
        'MooseX::FollowPBP' => 0,
        'Sort::Versions'    => 0,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    meta_merge => {
        resources => {
            repository  => 'http://github.com/cebjyre/Versionify-Dispatch',
        },
    },
    add_to_cleanup      => [ 'Versionify-Dispatch-*' ],
);

$builder->create_build_script();
