use ExtUtils::MakeMaker;

my $pm = 'UpDown';

WriteMakefile(
	NAME	=>	"Tk::$pm",
	DISTNAME => "Tk-$pm",
	VERSION_FROM => "$pm.pm",

	dist =>  {COMPRESS => 'gzip', SUFFIX => 'gz'},
	($] >= 5.005 ? 
		(ABSTRACT => 'Number Navigation Widget',
		AUTHOR => 'Sanjaysen') : ( ),
	),
);
