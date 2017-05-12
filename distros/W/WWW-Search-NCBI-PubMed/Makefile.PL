use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME              => 'WWW::Search::NCBI::PubMed',
	      VERSION_FROM      => 'lib/WWW/Search/NCBI/PubMed.pm', # finds $VERSION
	      PREREQ_PM         => 
	      { 
		  WWW::Search => 2.51,
		    URI => 1.28,
		    IO::Extended => 0.08,
		    File::Basename => 2.72,
		    Path::Class => 0.06,
		    Getopt::Long => 0,
		    Pod::Usage => 0,
		    LWP::UserAgent => 0,
		    URI => 0,
		    HTML::Entities => 0,
		    XML::LibXML => 0,
		    XML::LibXSLT => 0, 
		    XML::XPath => 0,
		    WWW::Search => 0,
		}, # e.g., Module::Name => 1.1
	      
	      EXE_FILES => [qw(script/pubmed.pl)],
	      
	      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM  => 'lib/WWW/Search/NCBI/PubMed.pm', # retrieve abstract from module
		AUTHOR         => 'Murat Uenalan <muenalan@cpan.org>') : ()),
	      );
