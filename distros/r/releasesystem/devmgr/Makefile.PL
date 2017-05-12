#
# MakeMaker config for the Release Manager Development side of the system.
# This should create a Makefile that runs just find on your system.
#
use 5.004;
use strict;
use vars qw(@SCRIPTS);

use ExtUtils::MakeMaker;

use IMS::ReleaseMgr 1.12; #need ftp functions from 1.11
			  #need make upgrades from 1.12

@SCRIPTS = qw(cvs_front_end dev_rls_tool);

WriteMakefile(
              NAME         => 'DevelManager',
              VERSION      => '0.3',
              EXE_FILES    => [@SCRIPTS],
              dist         => { COMPRESS => 'compress', SUFFIX => 'Z' },
             );
