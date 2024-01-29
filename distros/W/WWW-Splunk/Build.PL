use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'WWW::Splunk',
	license => 'perl',
	dist_author => 'Michal Josef Spacek <skim@cpan.org>',
	dist_version => '2.09',
	requires => {
		'perl' => 5.010,
		'Carp' => 0,
		'Date::Manip' => 0,
		'Getopt::Long' => 0,
		'HTTP::Request::Common' => 0,
		'LWP::UserAgent' => 0,
		'Pod::Usage' => 0,
		'XML::LibXML' => 0,
	},
	build_requires => {
		'Test::More' => 0,
		'XML::LibXML' => 0,
	},
	test_requires => {
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
		'XML::LibXML' => 0,
	},
	configure_requires => {
		'Module::Build' => 0.42,
	},
	meta_merge => {
		resources => {
			bugtracker => 'https://github.com/michal-josef-spacek/perl-WWW-Splunk/issues',
			repository => 'https://github.com/michal-josef-spacek/perl-WWW-Splunk',
		},
	},
	recursive_test_files => 1,
);

$build->create_build_script;
