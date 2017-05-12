use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Thread::Task::Concurrent',
    license            => 'perl',
    dist_author        => q{Joachim Bargsten <cpan at bargsten dot org>},
    dist_version_from  => 'lib/Thread/Task/Concurrent.pm',
    configure_requires => { 'Module::Build' => '0.36', },
    requires           => {
        'threads'         => 0,
        'threads::shared' => 0,
        'Mouse'           => 0,
        'Mouse::Exporter' => 0,
        'Thread::Queue'   => 0,
        'perl'            => '5.010',
    },
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['Thread-Task-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
