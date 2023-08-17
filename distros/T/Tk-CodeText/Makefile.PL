use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'CodeText';
my $ld = '$(INST_LIBDIR)';

WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => {
		'File::Path' => 0,
		'Math::Round' => 0,
		'Syntax::Kamelon' => '0.23',
		'Test::Tk' => '2.00',
		'Tk' => '800.024',
		'Tk::ColorEntry' => '0.03',
		'Tk::GtkSettings' => '0.05',
		'Tk::PopList' => '0.04',
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
		}}) : ()
	),
);
