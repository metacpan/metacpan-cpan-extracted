use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::Atom::Service',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/XML/Atom/Service.pm',
    requires => {
        'version'    => 0,
        'XML::Atom'  => 0.27,
    },
    build_requires => {
        'Test::More'           => 0,
        'Test::NoWarnings'     => 0,
#        'Test::Perl::Critic'   => 0,
#        'Test::Pod'            => 1.14,
#        'Test::Pod::Coverage'  => 1.04,
    },
    add_to_cleanup      => [ 'XML-Atom-Service-*' ],
);

$builder->create_build_script();
