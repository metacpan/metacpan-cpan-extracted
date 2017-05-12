#-------------------------------------------------
 use ExtUtils::MakeMaker;
#-------------------------------------------------
 WriteMakefile(
 	NAME			=> 'Tk::Schedule',
 	VERSION_FROM	=> 'lib/Tk/Schedule.pm',	# finds $VERSION
 	PREREQ_PM		=> 
 		{
 		Tk		=> '0',
 		Tk::Frame	=> '0',
 		Tk::Photo	=> '0',
 		Tk::TimePick	=> '0.02',
 		Tk::ChooseDate	=> '0',
 		Date::Calc	=> '5.4',
 		Bit::Vector	=> '6.4',
 		Carp::Clan	=> '5.3',
 		Time::Local	=> '0',
 		Storable		=> '2.05',
 		B::Deparse	=> '0'
 		},					# e.g., Module::Name => 1.1
 	($] >= 5.005 ?					## Add these new keywords supported since 5.005
 	(ABSTRACT_FROM	=> 'lib/Tk/Schedule.pm',	# retrieve abstract from module
 	AUTHOR		=> 'Torsten Knorr <torstenknorr@tiscali.de>') : ()),
 	);
#-------------------------------------------------







