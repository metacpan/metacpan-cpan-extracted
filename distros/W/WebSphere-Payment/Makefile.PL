
# $Id: Makefile.PL,v 1.1 20010612 11:33 luis@cantv.net

use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

WriteMakefile 
  (
   'NAME'         => 'WebSphere::Payment',
   'VERSION_FROM' => 'Payment.pm',
   'PREREQ_PM'    => { 'HTTP::Headers' => '', 'HTTP::Request' => '', 
		       'LWP::UserAgent' => '' },
   'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
    ($] ge '5.005')
        ? (
            'AUTHOR' => 'Luis Moreno <luis@cantv.net>',
            'ABSTRACT' => 'Simple Perl API interface to IBM Payment Manager 2.2',
           )
         : (),
  );