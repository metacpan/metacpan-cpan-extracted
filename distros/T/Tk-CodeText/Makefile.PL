use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'CodeText';

WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => {
		'File::Path' => '2.18',
		'File::Spec' => '3.75',
		'Getopt::Long' => '2.54',
		'Math::Round' => '0.08',
		'Syntax::Kamelon' => '0.24',
		'Test::Tk' => '3.03',
		'Tk' => '804.030',
		'Tk::ColorEntry' => '0.11',
		'Tk::PopList' => '0.09',
		'Tk::YADialog' => '0.05',
	},
	ABSTRACT_FROM => "lib/Tk/$pm.pm",
	VERSION_FROM => "lib/Tk/$pm.pm",
	AUTHOR => 'Hans Jeuken <hanje at cpan dot org>',
	EXE_FILES => ['bin/codetext'],
	LICENSE	=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-CodeText.git',
				web  => 'https://github.com/haje61/Tk-CodeText',
			},
			bugtracker => {
				web  => "https://github.com/haje61/Tk-CodeText/issues",
			},
		}}) : ()
	),
);

