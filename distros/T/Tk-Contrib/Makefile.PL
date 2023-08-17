use ExtUtils::MakeMaker;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $version = '0.08';

WriteMakefile(
	NAME => "Tk::Contrib",
	VERSION => $version,
	PREREQ_PM => {
		'Test::Tk' => '3.00',
		'Tk' => '800.024',
	},
	LICENSE	=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/haje61/Tk-Contrib.git',
				web  => 'https://github.com/haje61/Tk-Contrib',
			},
		}}) : ()
	),
);
