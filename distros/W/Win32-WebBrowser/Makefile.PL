# -*- perl -*-

require 5.008;
use strict;
require ExtUtils::MakeMaker;

eval { require 5.008 } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#######################################
EOD

unless ($^O eq 'MSWin32') {
	die <<'EOMSG';
#######################################
#	This module is only intended for Microsoft
#	Windows platforms.
#######################################
EOMSG
}

ExtUtils::MakeMaker::WriteMakefile(
	'NAME' => 'Win32::WebBrowser',
	'VERSION_FROM' => 'lib/Win32/WebBrowser.pm',
	'dist'         => { 
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' 
	 },
   	'AUTHOR' => 'Dean Arnold, Presicient Corp. (info@presicient.com)',
   	'ABSTRACT' => 'Start up a default browser in a separate process on Windows',
   	'PREREQ_PM' => {
   		'Win32::TieRegistry' => '0.0',
   		'Win32::Process' => '0.0'
   	}
);
