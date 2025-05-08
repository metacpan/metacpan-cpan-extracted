use ExtUtils::MakeMaker;

use strict;
use warnings;

my $name = 'Tk::ListBrowser';
my $pm = 'lib/Tk/ListBrowser.pm';
my $git = 'Tk-ListBrowser';

my %prereq = (
	#package          =>  version
	'Convert::Color'    => '0.18',
	'Math::Round'       => '0.08',
	'Tk'                => '804.033',
	'Test::Tk'          => '3.04',
);

WriteMakefile(
	NAME					=> $name,
	VERSION_FROM		=> $pm,
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> $pm,
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
		repository => {
			type => 'git',
			url  => "git://github.com/haje61/$git.git",
			web  => "https://github.com/haje61/$git",
		},
		bugtracker => {
			web  => "https://github.com/haje61/$git/issues",
		},
	}}
	) : () ),
);

