use ExtUtils::MakeMaker;

use strict;
my %prereq = (
	'Test::Tk'            => '3.03',
	'Tk'                  => '804.032',
);

WriteMakefile(
	NAME					=> 'Tk::DynaMouseWheelBind',
	VERSION_FROM		=> 'lib/Tk/DynaMouseWheelBind.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/Tk/DynaMouseWheelBind.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/Tk-DynaMouseWheelBind.git',
            web  => 'https://github.com/haje61/Tk-DynaMouseWheelBind',
         },
         bugtracker => {
            web  => "https://github.com/haje61/Tk-DynaMouseWheelBind/issues",
         },
      }}
    ) : () ),
);


