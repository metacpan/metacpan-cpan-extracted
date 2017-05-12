use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::SlideShare',
    VERSION_FROM      => 'lib/WWW/SlideShare.pm', # finds $VERSION
    PREREQ_PM         => {
				'Carp' => 0,
				'Digest::SHA1' => 0,
				'LWP::UserAgent' => 0,
				'XML::Parser' => 0,
			 }, 
# e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/SlideShare.pm', # retrieve abstract from module
       AUTHOR         => 'Ashish . Mukherjee <ashish.mukherjee@gmail.com>') : ()),
);
