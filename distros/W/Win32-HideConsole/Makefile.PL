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
	'NAME' => 'Win32::HideConsole',
	'VERSION_FROM' => 'lib/Win32/HideConsole.pm',
	'dist'         => { 
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf' 
	 },
   	'AUTHOR' => 'phatWares, USA (phantomsea2005@yahoo.com)',
   	'ABSTRACT' => 'Hides console window for GUI applications',
   	'PREREQ_PM' => {
   		'Win32' => '0.0',
   		'Win32::API' => '0.0'
   	}
);
