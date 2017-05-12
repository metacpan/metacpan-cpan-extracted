use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME                => 'WWW::Video::Streamer',
			  AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
			  VERSION_FROM        => 'lib/WWW/Video/Streamer.pm',
			  ABSTRACT_FROM       => 'lib/WWW/Video/Streamer.pm',
			  ($ExtUtils::MakeMaker::VERSION >= 6.3002
			   ? ('LICENSE'=> 'perl')
			   : ()),
			  PL_FILES            => {},
			  INST_SCRIPT => 'bin',
			  PREREQ_PM => {
							'Test::More'=>0,
							'Config::IniHash'=>0,
							'Text::NeatTemplate'=>0,
							'String::ShellQuote'=>0,
							'CGI'=>0,
							'File::MimeInfo'=>0,
							'Cwd'=>0,
							},
			  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
			  clean               => { FILES => 'WWW-Video-Streamer-*' },
			  );
