use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Text::Metaphone::Amharic',
	'DISTNAME'	=> 'Text-Metaphone-Amharic',
	'VERSION_FROM'	=> 'lib/Text/Metaphone/Amharic.pm',
	'AUTHOR'	=> "Daniel Yacob <dyacob\@cpan.org>",
	'ABSTRACT'	=> "The Metaphone Algorithm for Amharic.",
	'dist'		=>	{ 
		'COMPRESS'	=>	"gzip -9f",
		'SUFFIX'	=>	"gz",
		'POSTOP'	=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	'PREREQ_PM' 	=> { 'Regexp::Ethiopic' => 0.06 },
	'LICENSE'	=> 'perl',
	'MIN_PERL_VERSION' => '5.8.0'
);
