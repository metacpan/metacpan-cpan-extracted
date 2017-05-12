#-------------------------------------------------
 use ExtUtils::MakeMaker;
#-------------------------------------------------
 WriteMakefile(
 	NAME			=> 'Tk::TimePick',
 	VERSION_FROM	=> 'lib/Tk/TimePick.pm',	# finds $VERSION
 	PREREQ_PM		=> {
 				Tk::Frame	=> '0',
 				}, # e.g., Module::Name => 1.1
 	($] >= 5.005 ?					## Add these new keywords supported since 5.005
 	(ABSTRACT_FROM	=> 'lib/Tk/TimePick.pm',	# retrieve abstract from module
 	AUTHOR		=> 'Torsten Knorr <torstenknorr@tiscali.de>') : ()),
 	);
#-------------------------------------------------


