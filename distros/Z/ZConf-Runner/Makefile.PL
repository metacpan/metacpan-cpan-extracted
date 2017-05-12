use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZConf::Runner',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/ZConf/Runner.pm',
    ABSTRACT_FROM       => 'lib/ZConf/Runner.pm',
    PL_FILES            => {},
    INST_SCRIPT => 'bin',
    PREREQ_PM => {
				  'Test::More' => 0,
				  'ZConf' => 0,
				  'Curses::UI' => 0,
				  'File::MimeInfo::Magic' => 0,
				  'File::MimeInfo::Applications' => 0,
				  'ZConf::GUI'=>0,
				  'String::ShellQuote'=>0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZConf-Runner-*' },
);
