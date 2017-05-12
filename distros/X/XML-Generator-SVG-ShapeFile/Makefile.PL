use strict;
use ExtUtils::MakeMaker;

WriteMakefile('NAME'	=> 'XML::Generator::SVG::ShapeFile',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => 'Generate SAX2 events for an SVG rendering of an ESRI shapefile.') : (),
	      'VERSION_FROM' => 'lib/XML/Generator/SVG/ShapeFile.pm',
	      'PREREQ_PM'    => {'Geo::ShapeFile' => '0',
				 'Date::Simple'   => '0',
				 'Test::More'     => '0'},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
);
