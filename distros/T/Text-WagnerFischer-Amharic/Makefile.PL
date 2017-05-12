use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Text::WagnerFischer::Amharic',
	'DISTNAME'	=> 'Text-WagnerFischer-Amharic',
	'VERSION_FROM'	=> 'lib/Text/WagnerFischer/Amharic.pm', # finds $VERSION
	'AUTHOR'	=> "Daniel Yacob <Yaocb\@EthiopiaOnline.Net>",
	'ABSTRACT'	=> "The WagnerFischer Algorithm Applied to Amharic.",
	dist			=>	{
		COMPRESS        =>	"gzip -9f",
		SUFFIX          =>	"gz",
		POSTOP          =>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	PREREQ_PM 	=> { 'Regexp::Ethiopic' => 0.06, 'Text::WagnerFischer' => 0.03 },
);
