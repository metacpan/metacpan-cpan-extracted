use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile
(
	'NAME'          => 'Tk::Taxis',
	'VERSION_FROM'  => 'lib/Tk/Taxis.pm',
	'PREREQ_PM'     => { Tk => 800.024 },
	'EXE_FILES'     => [ 'eg/woodlice.pl' ],
    (
    	$] >= 5.005 ?
     		(
				ABSTRACT_FROM => 'lib/Tk/Taxis.pm',
				AUTHOR        => 'Steve Cook <steve@steve.gb.com>'
			) : 
				()
	),
);
