use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'threads::variables::reap',
    license             => 'perl',
    dist_author         => q{Jens Rehsack <rehsack@cpan.org>},
    dist_version_from   => 'lib/threads/variables/reap.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'threads-variables-reap-*' ],
    requires            => {
    },
    recommends          => {
	threads         => 0,
    },
    meta_merge =>
	{ resources => { repository => "https://github.com/rehsackthreads-variables-reap", }, },
    test_files => join( ' ' => 't/*.t xt/*.t' ),
);

$builder->create_build_script();
