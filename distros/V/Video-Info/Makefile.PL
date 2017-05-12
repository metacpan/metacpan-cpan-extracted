use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Video::Info',
    'VERSION_FROM'	=> 'Info.pm', # finds $VERSION
    'PREREQ_PM'		=> {    Video::OpenQuicktime         => 1.0,
				Class::MakeMethods::Emulator => 1.0,
				MP3::Info                    => 1.0,
			    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Info.pm', # retrieve abstract from module
       AUTHOR     => 'Allen Day <allenday@ucla.edu>') : ()),
);
