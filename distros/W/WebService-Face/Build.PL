use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'WebService::Face',
    license           => 'perl',
    dist_author       => q{Arnaud (Arhuman) ASSAD <arhuman@gmail.com>},
    dist_version_from => 'lib/WebService/Face/Client.pm',
    build_requires    => {
        'JSON'         => 0,
        'REST::Client' => 0,
        'Storable'     => 0,
        'Test::More'   => 0,
    },
    requires           => { 'perl' => 5.006, },
    add_to_cleanup     => ['WebService-Face-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        resources => {
            repository => q[https://github.com/arhuman/WebService-Face],
            bugtracker => q[https://github.com/arhuman/WebService-Face/issues],
        },
        keywords     => [qw[face recognition rest api]],
        generated_by => q[Arnaud (Arhuman) ASSAD <arhuman@gmail.com>]
    },
);

$builder->create_build_script();
