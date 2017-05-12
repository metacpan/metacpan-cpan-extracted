use ExtUtils::MakeMaker;

my $pm = 'DataControl';

WriteMakefile(
	NAME	=>	"Tk::$pm",
	DISTNAME => "Tk-$pm",
	VERSION_FROM => "$pm.pm",

	dist =>  {COMPRESS => 'gzip', SUFFIX => 'gz'},
	($] >= 5.005 ? 
		(ABSTRACT => 'Record Navigation Widget From Table',
		AUTHOR => 'Sanjaysen') : ( ),
	),
);
