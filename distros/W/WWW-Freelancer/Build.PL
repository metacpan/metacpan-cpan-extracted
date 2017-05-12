use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    'module_name'       => 'WWW::Freelancer',
    'license'           => 'perl',
    'dist_author'       => 'Alan Haggai Alavi <haggai@cpan.org>',
    'dist_version_from' => 'lib/WWW/Freelancer.pm',
    'build_requires'    => { 'Test::More' => 0 },
    'requires'          => {
        'version'        => 0,
        'LWP::UserAgent' => 0,
        'JSON'           => 0,
    },
    'meta_merge' => {
        'resources' =>
          { 'repository' => 'git://github.com/alanhaggai/WWW-Freelancer.git', },
    },
    'add_to_cleanup' => ['WWW-Freelancer-*'],
);

$builder->create_build_script();
