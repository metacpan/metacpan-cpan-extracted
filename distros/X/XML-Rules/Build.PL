use strict;
use warnings;
use Module::Build;
use Module::Build::Compat;

my $builder = Module::Build->new(
    module_name         => 'XML::Rules',
    license             => 'perl',
    dist_author         => 'Jan Krynicky <Jenda@CPAN.org>',
    dist_version_from   => 'lib/XML/Rules.pm',
	requires => {
		'perl'          => '5.008',
		'XML::Parser'  => '2.00',
		'XML::Parser::Expat' => '2.00',
    },
	recommends => {
		'XML::DTDParser' => '2.00',
	},
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'XML-Rules-*' ],
	dynamic_config  => 0,
	create_makefile_pl => 'small',
    create_license  => 1,
);

$builder->create_build_script();
