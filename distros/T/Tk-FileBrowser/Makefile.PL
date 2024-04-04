use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'FileBrowser';
my $ld = '$(INST_LIBDIR)';

WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => {
		'File::Basename' => 0,
		'Test::Tk' => '3.02',
		'Tk' => '800.024',
		'Tk::ITree' => '0.03',
		'Tk::ListEntry' => '0.02',
	},
	ABSTRACT_FROM => "lib/Tk/$pm.pm",
	VERSION_FROM => "lib/Tk/$pm.pm",
	AUTHOR => 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE	=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "git://github.com/haje61/Tk-$pm.git",
				web  => "https://github.com/haje61/Tk-$pm",
			},
		}}) : ()
	),
);





