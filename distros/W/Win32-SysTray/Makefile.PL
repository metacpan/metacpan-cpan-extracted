use ExtUtils::MakeMaker;
use strict;
use diagnostics;

ExtUtils::MakeMaker::WriteMakefile(
	'NAME'  => 'Win32::SysTray',
	'VERSION_FROM'  => 'SysTray.pm',
    'PREREQ_FATAL' => 1,
	'PREREQ_PM' => {
        'Test' => 0,
        'Win32' => 0,
        'Win32::Mutex' => 0,
        'Win32::GUI' => "1.03"        
    },
	'clean' => {
        'FILES' => 'Win32-SysTray-*'
    },
);
