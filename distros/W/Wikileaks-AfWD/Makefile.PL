use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'Wikileaks::AfWD',
			  AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
			  VERSION_FROM        => 'lib/Wikileaks/AfWD.pm',
			  ABSTRACT_FROM       => 'lib/Wikileaks/AfWD.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More'=>0,
							'Text::NeatTemplate'=>0,
							'Text::Autoformat'=>0,
							'DBI'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'Wikileaks-AfWD-*' },
			  );
