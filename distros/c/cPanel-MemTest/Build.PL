use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'cPanel::MemTest',
    author              => 'Daniel Muey <dmuey@cpan.org>',
    dist_version_from   => 'lib/cPanel/MemTest.pm',
    license             => 'perl',
    build_requires      => {
	'Test::More'    => '0.40', 
	'Module::Build' => '0.3603',
	'Test::Warn'    => '0.21'
	},
    abstract_from       => 'lib/cPanel/MemTest.pm',
    add_to_cleanup      => ['cPanel-MemTest-*' ],
    create_makefile_pl  => 'small',
    autosplit           => 'lib/cPanel/MemTest.pm',
);

$builder->create_build_script;
