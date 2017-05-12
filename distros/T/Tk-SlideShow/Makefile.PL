#!/usr/local/bin/perl5
# Date de création : Wed May 19 05:25:43 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)

use ExtUtils::MakeMaker;

WriteMakefile(
	      'PREREQ_PM'	=> { "Tk"		=> "800.012",
				     "X11::Protocol"     => "0.04"},
	      'NAME'	=> 'Tk::SlideShow',
	      'VERSION_FROM' => 'SlideShow.pm', # finds $VERSION
);
# Local Variables: ***
# mode: perl ***
# End: ***
