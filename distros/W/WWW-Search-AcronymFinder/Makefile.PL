use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'WWW::Search::AcronymFinder',
	      'VERSION_FROM'	=> 'AcronymFinder.pm', # finds $VERSION
	      'PREREQ_PM'		=> {'WWW::Search' => 0},
	      'EXE_FILES' => [ <bin/*> ],
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'AcronymFinder.pm', # retrieve abstract from module
		AUTHOR     => 'xern <xern@cpan.org>') : ()),
	      );
