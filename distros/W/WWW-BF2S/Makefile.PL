use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::BF2S',
    VERSION_FROM      => 'lib/WWW/BF2S.pm', # finds $VERSION
    PREREQ_PM         => { 'XML::Simple' => "2.14", # probably could use an older version
			   'LWP::Simple' => "1.41", # probably could use an older version
			   'Data::Dumper' => "2.121", # probably could use an older version
			  },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/BF2S.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <bf2s-module@dusty.hey.nu>') : ()),
);
