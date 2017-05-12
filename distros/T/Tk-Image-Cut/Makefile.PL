#-------------------------------------------------
use ExtUtils::MakeMaker;
#-------------------------------------------------
 WriteMakefile(
 	NAME			=> 'Tk::Image::Cut',
 	VERSION_FROM	=> 'lib/Tk/Image/Cut.pm',			# finds $VERSION
 	PREREQ_PM		=> {
 				'Tk'			=> '804.027',
 				'Tk::Frame'		=> '0',
 				'Tk::FileSelect'		=> '4.015',
 				'Tk::JPEG'		=> '0',
 				'Tk::PNG'		=> '4.003',
 				'Tk::Image::Calculation'	=> '0.04',
 				},					# e.g., Module::Name => 1.1
 	($] >= 5.005 ?							## Add these new keywords supported since 5.005
 	(ABSTRACT_FROM	=> 'lib/Tk/Image/Cut.pm',			# retrieve abstract from module
 	AUTHOR		=> 'Torsten Knorr <torstenknorr@tiscali.de>') : ()),
 	);
#-------------------------------------------------





