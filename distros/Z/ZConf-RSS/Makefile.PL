use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'ZConf::RSS',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/ZConf/RSS.pm',
			  ABSTRACT_FROM       => 'lib/ZConf/RSS.pm',
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More' => 0,
							'ZConf'=>0,
							'XML::FeedPP'=>0,
							'Text::NeatTemplate'=>0,
							'HTML::FormatText::WithLinks'=>0,
							'ZConf::GUI'=>0
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'ZConf-RSS-*' },
			  );
