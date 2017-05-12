use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::WWW::Mechanize::Maypole',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Test/WWW/Mechanize/Maypole.pm',
    requires => {
        'Test::More' => 0,
        'Test::WWW::Mechanize' => 0,
        'Maypole' => 2,
        'HTTP::Status' => 0,
        'URI' => 0,
        'HTTP::Headers::Util' => 0,
        'Class::Data::Inheritable' => 0,
        'UNIVERSAL::require' => 0,
    },
    add_to_cleanup      => [ 'Test-WWW-Mechanize-Maypole-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();

