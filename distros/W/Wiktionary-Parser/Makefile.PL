use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Wiktionary::Parser',
	AUTHOR              => q{Chris Becker <clbecker@gmail.com>},
	VERSION_FROM        => 'lib/Wiktionary/Parser.pm',
	ABSTRACT_FROM       => 'lib/Wiktionary/Parser.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'MediaWiki::API' => 0,
		'Locale::Codes' => 0,
		'Locale::Codes::Language' => 0,
		'Locale::Codes::Constants' => 0, # attempting to fix error in cpan testers report
		'Text::Unidecode' => 0,
		'Carp::Always' => 0,
		'File::Path' => 0,
		'Test::More' => 0,
	},
	META_MERGE => {
		resources => {
			license => 'http://dev.perl.org/licenses/',
			homepage => 'https://github.com/clbecker/perl-wiktionary-parser/wiki',
			repository => 'https://github.com/clbecker/perl-wiktionary-parser/',
		},
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Wiktionary-Parser-*' },
);
