use strict;
use warnings;
use Module::Build;

use 5.008;

my $builder = Module::Build->new(
    module_name         => 'emailvalidation',
    license             => 'perl',
    dist_author         => 'Dominik Kukacka <dominik@everapi.com>',
    dist_abstract       => 'validate & verify any email address',
    create_makefile_pl  => 0,     #'traditional',
    create_readme       => 0,
    requires            => {
        'File::Basename'      => '0',
        'Moose'               => '0.24',
    },
    build_requires      => {
        'Test::More'          => '0.47',
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/everapihq/emailvalidation-perl',
            bugtracker => 'https://github.com/everapihq/emailvalidation-perl/issues'
        }
    },
);

$builder->create_build_script();
