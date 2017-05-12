use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Thread::CriticalSection',
    license             => 'perl',
    dist_author         => 'Pedro Melo <melo@cpan.org>',
    dist_version_from   => 'lib/Thread/CriticalSection.pm',
    build_requires => {
        'Thread::Semaphore' => 0,
        'Test::More'         => 0,
    },
    add_to_cleanup      => [ 'Thread-CriticalSection-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
