use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'FileBrowser';
use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';

my %prereq = (
	'File::Basename' => 0,
	'File::Spec' => 0,
	'File::Spec::Link' => '0.073',
	'Test::Tk' => '3.04',
	'Tk' => '804.032',
	'Tk::ListBrowser' => '0.12',
	'Tk::ListEntry' => '0.07',
	'Tk::YADialog' => '0.05',
);

if ($mswin) {
	$prereq{'File::MimeInfo::Simple'} = '0.7'
} else {
	$prereq{'File::MimeInfo'} = '0.35'
}


WriteMakefile(
	NAME => "Tk::$pm",
	PREREQ_PM => \%prereq,
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
			bugtracker => {
				web  => "https://github.com/haje61/Tk-$pm/issues",
			},
		}}) : ()
	),
);







