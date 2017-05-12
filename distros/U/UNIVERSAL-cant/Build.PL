use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'UNIVERSAL::cant',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/UNIVERSAL/cant.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'UNIVERSAL-cant-*' ],
);

$builder->create_build_script();
