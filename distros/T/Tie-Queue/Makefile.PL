#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     NAME      => 'Tie::Queue',
     VERSION_FROM => 'lib/Tie/Queue.pm', # finds $VERSION
     ABSTRACT       => 'Tie::Queue Is a tie ARRAY over a TokyoTyrant database used as a Queue system',
     dist => { COMPRESS=>"gzip -f", SUFFIX=>"gz" }, 
     PREREQ_PM => { 'TokyoCabinet' , 'Data::Serializer' },
     PREREQ_FATAL => 1,
);
