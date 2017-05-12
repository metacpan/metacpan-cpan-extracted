use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'Tk::Preferences',
    'VERSION_FROM'	=> 'Preferences.pm',
    'PREREQ_PM'		=> {
    	'Tk'		=> '800.024'
    },
    'AUTHOR'		=> 'Andrew N. Hicox <andrew@hicox.com>',
);
