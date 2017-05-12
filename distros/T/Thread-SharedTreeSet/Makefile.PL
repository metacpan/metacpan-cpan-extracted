#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;
require 5.006;
my @basics = ( AUTHOR       => 'David Helkowski <cpan@codechild.com>',
               ABSTRACT     => 'Shared set of recursive hashes/arrays using serialization.',
               NAME         => 'Thread::SharedTreeSet',
               VERSION_FROM => 'SharedTreeSet.pm',
               PREREQ_PM    => {
               }
             );
{
    no warnings 'numeric';
    if( ( $ExtUtils::MakeMaker::VERSION *1 ) >= 6.31 ) {
      push( @basics, LICENSE => 'perl' );
    }
}

WriteMakefile( @basics );
