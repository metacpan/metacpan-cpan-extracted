use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Mail',
    license             => 'perl',
    dist_author         => 'Kirrily Robert <skud@cpan.org>',
    dist_version_from   => 'lib/Test/Mail.pm',
    build_requires => {
        'Test::More' => 0,
        'Mail::Header' => 0,
    },
    add_to_cleanup      => [ 'Test-Mail-*' ],
);

$builder->create_build_script();
