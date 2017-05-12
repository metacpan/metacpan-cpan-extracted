#
# Revision History:
#
#   18-May-2003 Dick Munroe (munroe@csworks.com)
#       Get the version number from script/kif.
#
#   20-May-2003 Dick Munroe (munroe@csworks.com)
#       Backport to 5.6.1
#

use ExtUtils::MakeMaker;

require 5.6.1 ;

my @scripts = qw(kif) ;

WriteMakefile
   (NAME => "kif",
    VERSION_FROM => "./script/kif",
    EXE_FILES => [ map { "script/$_" } @scripts ], 
    PREREQ_PM => {'File::Basename' => 2.6,
		  'File::Copy' => 2.03,
		  'File::stat' => 1.00,
		  'FileHandle' => 2.00,
		  'Getopt::Long' => 2.25,
		  'StanzaFile' => 1.00
	      },
    ($[ >= 5.005) ?
        (AUTHOR   => 'Dick Munroe (munroe@csworks.com)',
         ABSTRACT => 'Kernel Installation Facility script and support modules') : (),
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'}
   );
