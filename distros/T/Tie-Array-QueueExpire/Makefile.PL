#!/usr/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     NAME      => 'Tie::Array::QueueExpire',
     VERSION_FROM => 'lib/Tie/Array/QueueExpire.pm', # finds $VERSION
     ABSTRACT       => 'Tie::Array::QueueExpire Is a tie ARRAY over a TokyoCabinet::BDB database with expiration function',
     dist => { COMPRESS=>"gzip -f", SUFFIX=>"gz" }, 
     PREREQ_PM => { 'DBD::SQLite' => 0 , 'Time::HiRes' => 0 },
);
