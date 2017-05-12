use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::AtMovies::TV',
    license             => 'perl',
    dist_author         => 'Alec Chen <alec@cpan.org>',
    dist_version_from   => 'lib/WWW/AtMovies/TV.pm',
    build_requires => {
        'Test::More'         => 0,
        'version'            => 0.76,
        'WWW::Mechanize'     => 1.34,
        'HTML::TableExtract' => 2.1,
        'Moose'              => 0.55,
    },
    add_to_cleanup      => [ 'WWW-AtMovies-TV-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
