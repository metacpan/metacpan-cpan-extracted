use strict;
use warnings;
use Module::Build;
use Config;

my $builder = Module::Build->new(
    module_name         => 'Web::DataService',
    license             => 'perl',
    dist_author         => 'Michael McClennen <mmcclenn@cpan.org>',
    dist_version_from   => 'lib/Web/DataService.pm',
    release_status => 'stable',
    requires => {
	'perl' => 5.012,
	'Dancer' => 1,
	'Moo' => 1,
        'namespace::clean' => 0.16,
        'HTTP::Validate' => 0.45,
	'JSON' => 2,
	'YAML' => 0,
    },
    recommends => {
	'Template' => 0,
	'Dancer::Plugin::Database' => 0,
    },
    configure_requires => {
	'Module::Build' => 0.42,
    },
    build_requires => {
	'Module::Build' => 0.42,
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Web-DataService-*' ],
    install_path => {
	 script => $Config{installbin},
    },
    script_files => {
    	'script/wdsinstallfiles' => 1 
    },
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
