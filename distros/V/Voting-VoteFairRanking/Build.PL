use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Voting::VoteFairRanking',
    license             => 'artistic_2',
    dist_author         => 'Richard Fobes <fobes@CPAN.org>',
    dist_version_from   => 'lib/Voting/VoteFairRanking.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Voting::VoteFairRanking-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

$builder->dispatch('build');
$builder->dispatch('test');
$builder->dispatch('install');
