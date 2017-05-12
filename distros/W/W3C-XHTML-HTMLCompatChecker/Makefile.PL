# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use ExtUtils::MakeMaker;

use Config;
use English;

# We needed perl >= 5.6.0 (use warnings...) but trying to do without
#use 5.006;

WriteMakefile(
    'NAME'              => 'W3C::XHTML::HTMLCompatChecker',
    'DISTNAME'          => 'W3C-XHTML-HTMLCompatChecker',
    'AUTHOR'            => 'the QA-dev tool development team at W3C http://www.w3.org/QA/Tools/qa-dev/',
    'ABSTRACT'		=> 'HTML Compatibility Checker for XHTML (aka Appendix C checker)',
    'VERSION'      	=> '0.10', 
    'PREREQ_PM'         => { 
'Exporter'       => 0,
 "XML::Parser" => 0,
 "CGI" => 0,
 "LWP::Simple" => 0,
 "URI" => 0,
 "CGI::Carp" => 0,
                           },
    'EXE_FILES'         => [ 'bin/appCcheck.pl' ],
    'dist'              => { COMPRESS => 'gzip -9f', SUFFIX => '.gz' },
);
