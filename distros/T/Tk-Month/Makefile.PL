use ExtUtils::MakeMaker;

WriteMakefile (
	NAME     		=> 'Tk::Month',
	VERSION_FROM	=> 'lib/Tk/Month.pm',
	DISTNAME	=> "Tk-Month",
	PREREQ_PM	=> {
		Time::Local	=> 1,
		Text::Abbrev=> 1,
		Tk			=> 800,
	},
	EXE_FILES	=> [ qw(bin/StrfClock bin/TkMonth) ],
	dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},

	ABSTRACT_FROM	=> 'lib/Tk/Month.pm', # retrieve abstract from module
	AUTHOR			=> 'Anthony R Fletcher, E<lt>arif@cpan.orgE<gt>',
	MIN_PERL_VERSION=> 5.014000,
	LICENSE			=> 'perl',
);

