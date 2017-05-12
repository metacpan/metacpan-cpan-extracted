use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tree::Authz',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Tree/Authz.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Tree-Authz-*' ],
);

$builder->create_build_script();
