use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'WWW::Search::Googlism',
	      'VERSION_FROM'	=> 'Googlism.pm',
	      'PREREQ_PM'	=> { 'WWW::Search' => 0 },
	      'EXE_FILES'       => [ <bin/*> ],
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'Googlism.pm',
		AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
