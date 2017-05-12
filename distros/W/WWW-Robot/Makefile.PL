#
# Makefile.PL for WWW::Robot distribution
#
# Filename:	Makefile.PL
# Author:	Neil Bowers
# Created:	11 March 1997
#

use ExtUtils::MakeMaker;


&WriteMakefile(
		NAME          => 'WWW::Robot',
		DISTNAME      => 'WWW-Robot',
		VERSION_FROM  => 'lib/WWW/Robot.pm',
		PREREQ_PM     => {
					'HTTP::Request' => 0,
					'HTTP::Status' => 0,
					'HTML::TreeBuilder' => 0,
					'URI::URL' => 0,
					'LWP::RobotUA' => 0,
					'IO::File' => 0,
                                        'HTML::LinkExtor' => 0,
                                 },
               dist          => {COMPRESS => 'gzip', SUFFIX => 'gz'},
              );
 
