#-------------------------------------------------
use ExtUtils::MakeMaker;
#-------------------------------------------------
 WriteMakefile(
 	NAME			=> 'Tk::Image::Calculation',
 	VERSION_FROM	=> 'lib/Tk/Image/Calculation.pm',	# finds $VERSION
 	PREREQ_PM		=> {},				# e.g., Module::Name => 1.1
 	($] >= 5.005 ?						## Add these new keywords supported since 5.005
 	(ABSTRACT_FROM	=> 'lib/Tk/Image/Calculation.pm',	# retrieve abstract from module
 	AUTHOR		=> 'Torsten Knorr <torstenknorr@tiscali.de>') : ()),
 	);
#-------------------------------------------------


