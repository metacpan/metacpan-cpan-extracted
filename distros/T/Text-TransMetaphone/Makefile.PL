
print STDERR "Using compatibility macros/routines for Perl 5.004\n"
    if ($] < 5.0045);



use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Text::TransMetaphone',
	'DISTNAME'	=> 'Text-TransMetaphone',
	'VERSION_FROM'	=> 'lib/Text/TransMetaphone.pm', # finds $VERSION
	dist		=>	{ 
		COMPRESS	=>	"gzip -9f",
		SUFFIX		=>	"gz",
		POSTOP		=>	'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
	AUTHOR		=> "Daniel Yacob <dyacob\@cpan.org>",
	ABSTRACT	=> "Translingual Phonetic Encoding of Words.",
	PREREQ_PM 	=> { 'Regexp::Ethiopic' => 0 },
);
