use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Coursera',
    license             => 'perl',
    dist_author         => q{Ovidiu N. Tatar <ovn.tatar@gmail.com>},
    dist_version_from   => 'lib/WWW/Coursera.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                         => 5.010,
    	'AnyEvent' => '7.07',
    	'Carp' => '1.32',
    	'File::Path' => '2.08_01',
    	'Mojolicious' => '4.67',
	'Moo'		=> '1.004002',
	},
    add_to_cleanup      => [ 'WWW-Coursera-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
