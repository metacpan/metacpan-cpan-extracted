use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'XML::CommonNS',
    license             => 'perl',
    dist_author         => 'Chris Prather <perigrin@cpan.org>',
    dist_version_from   => 'lib/XML/CommonNS.pm',
    requires => {
		'XML::NamespaceFactory'	=> 0,
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'XML-CommonNS-*' ],
);

$builder->create_build_script();
