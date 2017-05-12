#!/usr/bin/perl -w

# $Id: Makefile.PL,v 1.1.1.1 2008-09-02 23:55:12 cvscore Exp $

use strict;
use ExtUtils::MakeMaker;

my %opts	= (
  NAME              	=> 'WebService::Eulerian::Analytics',
  VERSION_FROM      	=> 'lib/WebService/Eulerian/Analytics.pm',
  );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
 @opts{qw/AUTHOR ABSTRACT/} = 
  ( 
   'Eulerian Technlogies Ltd. '.
   ' Guillaume Fougnies <guillaume@eulerian.com>'.
   ' Mathieu Jondet <mathieu@eulerian.com>',
   'Eulerian Analytics API Interface'
  );
}

WriteMakefile( %opts );


1;

