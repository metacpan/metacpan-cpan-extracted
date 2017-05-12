use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::phpBB',
    VERSION_FROM      => 'lib/WWW/phpBB.pm', # finds $VERSION
    PREREQ_PM         => {WWW::Mechanize => 0,
    		      	 Compress::Zlib => 0,
			 HTML::TokeParser::Simple => 0,
			 DBI => 0,
			 DBD::mysql =>0,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/phpBB.pm', # retrieve abstract from module
       AUTHOR         => 'Stefan Talpalaru <stefantalpalaru@yahoo.com>') : ()),
);
