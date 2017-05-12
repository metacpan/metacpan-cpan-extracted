use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Text::Metaphone::Amharic',
	'VERSION_FROM'	=> 'lib/Text/Metaphone/Amharic.pm',
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	AUTHOR		=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "The Metaphone Algorithm for Amharic.",
	PREREQ_PM 	=> { 'Regexp::Ethiopic' => 0.06 },
);
