use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Text::SpellChecker::GUI',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/Text/SpellChecker/GUI.pm',
			  ABSTRACT_FROM       => 'lib/Text/SpellChecker/GUI.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'Curses::UI' => 0,
							'String::ShellQuote' => 0,
							'ZConf::GUI' => 0,
							'Text::SpellChecker' => 0,
							'ZConf'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Text-SpellChecker-GUI-*' },
			  );
