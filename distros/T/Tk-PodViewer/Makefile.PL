use ExtUtils::MakeMaker;

use strict;
my %prereq = (
	'Getopt::Long',       => '2.54',
	'Pod::Simple'         => '3.43',
	'Test::Tk'            => '3.04',
	'Tk'                  => '804.030',
);

WriteMakefile(
	NAME					=> 'Tk::PodViewer',
	VERSION_FROM		=> 'lib/Tk/PodViewer.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/Tk/PodViewer.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	EXE_FILES => ['bin/podviewer'],
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/Tk-PodViewer.git',
            web  => 'https://github.com/haje61/Tk-PodViewer',
         },
         bugtracker => {
            web  => "https://github.com/haje61/Tk-PodViewer/issues",
         },
      }}
    ) : () ),
);