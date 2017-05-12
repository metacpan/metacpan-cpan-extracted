use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name	=> 'WWW::Splunk',
	license		=> 'perl',
	dist_author	=> 'Michal Josef Spacek <skim@cpan.org>',
	dist_version	=> '2.06',
	requires	=> {
		'perl'          => 5.010,
		'Carp'		=> 0,
		'Getopt::Long'	=> 0,
		'HTTP::Request::Common' => 0,
		'LWP::UserAgent' => 0,
		'Pod::Usage'	=> 0,
		'Test::More'	=> 0,
		'Text::CSV'	=> 0,
		'XML::LibXML'	=> 0,
		'Date::Manip'	=> 0,
	},
	build_requires => {
		'Test::More'	=> 0,
		'XML::LibXML'	=> 0,
	},
	meta_merge => {
		resources => {
			repository => 'https://github.com/tupinek/perl-WWW-Splunk',
		},
	},
);

$build->create_build_script;
