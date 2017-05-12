use ExtUtils::MakeMaker ;
use Config ;

if (! $Config{d_alarm}){
	die("Fatal error: alarm(2) is not defined on this system.\n") ;
}


WriteMakefile(
    'NAME'		=> 'Time::Out',
    'VERSION_FROM'	=> 'Out.pm',
);
