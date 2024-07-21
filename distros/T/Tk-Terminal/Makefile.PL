use ExtUtils::MakeMaker;

use strict;
use warnings;


my %prereq = (
	'Getopt::Long'        => '2.54',
	'IO::Handle'          => '1.52',
	'Test::Tk'            => '3.03',
	'Tk'                  => '804.031',
	'Tk::TextANSIColor'   => '0.15',
);

my $pm = 'lib/Tk/Terminal.pm';

WriteMakefile(
	NAME					=> 'Tk::Terminal',
	VERSION_FROM		=> $pm,
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> $pm,
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	EXE_FILES => ['bin/tkterm'],
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/Tk-Terminal.git',
            web  => 'https://github.com/haje61/Tk-Terminal',
         },
      }}
    ) : () ),
);

