#
# MakeMaker config for the IMS::ReleaseMgr package. This should create a
# Makefile that runs just fine on your system.
#
use ExtUtils::MakeMaker;

use LWP          5.42; # To ensure that LWP has dynamic file upload support
use Archive::Tar 0.21;

WriteMakefile(
              NAME         => 'IMS::ReleaseMgr',
              VERSION_FROM => 'ReleaseMgr.pm',
              PMLIBDIRS    => ['ReleaseMgr'],
              dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
             );
