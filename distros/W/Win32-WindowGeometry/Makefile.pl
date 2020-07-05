# -*- perl -*-

require 5.008;
use strict;
require ExtUtils::MakeMaker;

eval { require 5.008 } or die << 'EOD';
########################################################
# This module requires a minimum Perl version of 5.008 #
# Please upgrade!                                      #
########################################################
EOD

unless ($^O =~ m/mswin/i) {die <<'EOMSG';
########################################################
#	This module is only intended for Microsoft         #
#	Windows platforms.                                 #
########################################################
EOMSG
}

ExtUtils::MakeMaker::WriteMakefile(
	'NAME' => 'Win32::WindowGeometry',
	'VERSION_FROM' => 'lib/Win32/WindowGeometry.pm',
	'dist' =>	{
					'SUFFIX'       => 'gz',
					'COMPRESS'     => 'gzip -9vf'
				},
	'AUTHOR' => 'Brandon Bourret (phatwares@cpan.org)',
	'ABSTRACT' => 'Simple module to search for open windows by title and move/resize them',
	'PREREQ_PM' =>	{
						'Win32::API' => '0.0',
						'Win32::API::Callback' => '0.0',
					});