use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::Entities',
    license             => 'perl',
    dist_author         => 'Jan Oldřich Krůza <sixtease@cpan.org>',
    dist_version_from   => 'lib/XML/Entities.pm',
    requires => {
        Carp => 0,
        perl => '5.008',
    },
    build_requires => {
        'Test::More' => 0,
    },
    recommends => {
        'HTML::Parser' => 0,
    },
);

$builder->create_build_script();
