use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Text::Pipe::RandomCase',
    license           => 'perl',
    dist_version_from => 'lib/Text/Pipe/RandomCase.pm',
    requires          => {
        'parent'     => 0,
        'Text::Pipe' => 0
    },
    build_requires     => { 'Test::More' => 0, },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    meta_merge         => {
        resources =>
          { repository => 'http://github.com/mdom/text-pipe-randomcase', },
    },
);

$builder->create_build_script();
