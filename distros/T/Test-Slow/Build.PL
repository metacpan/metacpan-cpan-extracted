use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Slow',
    license             => 'perl',
    dist_author         => q{Tomáš Znamenáček <zoul@fleuron.cz>},
    dist_version_from   => 'lib/Test/Slow.pm',
    requires            => {
        'perl' => '5.008',
        'Test::More' => 0,
    },
    add_to_cleanup      => ['Test-Slow-*', '*.bak', 'Debian_CPANTS.txt'],
    create_makefile_pl  => 'traditional',
    meta_merge          => {
        resources => { repository => 'http://github.com/zoul/Test-Slow' },
    },
);

$builder->create_build_script;
