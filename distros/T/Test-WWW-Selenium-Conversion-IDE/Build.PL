################
# Created by: setitesuk
# Created on: 2009-11-06

use strict;
use warnings;
use Module::Build;
use lib qw(. lib);

our $VERSION = 0.5;

my $builder = Module::Build->new(
				 module_name         => 'Test::WWW::Selenium::Conversion::IDE',
				 dist_author         => q(Andy Brown <setitesuk@gmail.com>),
				 dist_version        => $VERSION,
				 dist_abstract       => q[module to during a test run convert on the fly Selenese IDE html to perl tests],
				 license             => 'lgpl3',
				 requires            => {
				   'XML::LibXML' => 0,
				   'Exporter'    => 0,
				   'Test::WWW::Selenium' => 0,
					 'Test::More' => '0.8',
					 'Readonly'   => 0,
					 'Carp'       => 0,
					 'English'    => 0,
				 },
				 recommends          => {
							},
				 build_requires      => {
               'Test::Exception' => 0,
               'JSON' => 0,
               'Test::MockObject' => 0,
							},
				 build_recommends    => {
							 'Test::Perl::Critic' => '1.116',
							 'Test::Distribution' => 0,
							 'Test::Kwalitee' => 0,
							 'Test::Pod' => 0,
							 'Test::Pod::Coverage' => 1.00,
							 
							},
				 create_makefile_pl  => 'small',
				 configure_requires  => { 'Module::Build' => 0.3603 }
				);

$builder->create_build_script();
