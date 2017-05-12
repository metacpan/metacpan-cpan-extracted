use utf8;
use Module::Build;

use Test::Manifest '2.00';

my $class = Test::Manifest->get_module_build_subclass;

$class->new(
	module_name => 'Unicode::Support',
	abstract    => 'Find out what supports what',
	dist_author => 'brian d foy <bdfoy@cpan.org>',
	license     => 'perl',
	
	requires => {
		'perl'  => '5.014',
		},
	
	build_requires => {
		'Test::More'     => '0',
		'Test::Manifest' => '2.00',
		},
	
	recommends => {
		'Test::Pod'           => '0',
		'Test::Pod::Coverage' => '0',
		},
	
	script_files => [],
	
	add_to_cleanup => [ 'Unicode-*' ],
	)->create_build_script;
