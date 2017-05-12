use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'Tk::mySplashScreen',
    'VERSION_FROM'	=> 'mySplashScreen.pm',
    'ABSTRACT_FROM'	=> 'mySplashScreen.pod',
    'AUTHOR'		=> 'Andrew N. Hicox <andrew@hicox.com>',
    'PREREQ_PM'		=> {
    	'Tk'				=> '800.024'
    },
    'PM'			=> {
    	"mySplashScreen.pm"		=> "\$(INST_LIBDIR)/mySplashScreen.pm",
    	"default.gif"			=> "\$(INST_LIBDIR)/mySplashScreen/default.gif",
    }
);
