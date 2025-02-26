use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'ColorEntry';
my $ld = '$(INST_LIBDIR)';

WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => {
		'Imager' => '1.019',
		'Imager::Screenshot' => '0.014',
		'Math::Round' => '0.08',
		'Test::Tk' => '3.03',
		'Tk' => '804.030',
		'Tk::PopList' => '0.09',
	},
	ABSTRACT_FROM => "lib/Tk/$pm.pm",
	VERSION_FROM => "lib/Tk/$pm.pm",
	AUTHOR => 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-ColorEntry.git',
				web  => 'https://github.com/haje61/Tk-ColorEntry',
			},
		}}) : ()
	),
);
