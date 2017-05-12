#
# MakeMaker config for the Release Manager system. This should create a
# Makefile that runs just find on your system.
#
use 5.004;
use strict;
use vars qw(@SCRIPTS);
use subs qw(get_examples);

use ExtUtils::MakeMaker;

use IMS::ReleaseMgr 1.05;  # Not actually used, just to check that it's here
use LWP             5.42; # ditto -- first LWP to have dynamic file upload
use Archive::Tar    0.21;
use Digest::MD5     2.09;

@SCRIPTS = qw(rlsmgrd deploy_content process_content roll_rm_logs upload.pl);

WriteMakefile(
              NAME          => 'ReleaseManager',
              VERSION       => '1.9',
              INSTALLSCRIPT => '/opt/ims/ahp-bin',
              EXE_FILES     => [@SCRIPTS],
              dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
             );
