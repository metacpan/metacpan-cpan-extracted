use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Toader',
	AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM        => 'lib/Toader.pm',
	ABSTRACT_FROM       => 'lib/Toader.pm',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
	PL_FILES            => {},
	INST_SCRIPT => 'bin',
	MIN_PERL_VERSION => '5.18.4',
	PREREQ_PM => {
		'Test::More'=>0,
		'Cwd'=>0,
		'Config::Tiny'=>'2.14',
		'Email::MIME'=>'1.910',
		'File::MimeInfo'=>'0.16',
		'Error::Helper'=>'1.0.0',
		'Module::List'=>'0.003',
		'Text::Template'=>'1.45',
		'Getopt::Std'=>0,
		'Term::CallEditor'=>'0.60',
		'Sys::Hostname'=>0,
		'File::Path'=>'2.08',
		'File::Spec'=>0,
		'Time::HiRes'=>'1.9725',
		'Date::Parse'=>0,
		'Email::Address'=>'1.89.5',
		'Pod::Simple::HTML'=>0,
		'File::Copy'=>0,
		'File::Temp'=>'0.22',
		'File::Spec'=>0,
		'Image::ExifTool'=>'8.90',
		'GD::Thumbnail'=>'1.35',
		'Text::Tags'=>'0.04',
		'Script::isAperlScript'=>'1.0.0',
		'Pod::WikiDoc'=>'0.18',
		'DBD::SQLite'=>'1.40',
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Toader-*' },
	);
