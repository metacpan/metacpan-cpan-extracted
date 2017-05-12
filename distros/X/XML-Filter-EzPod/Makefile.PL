#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    VERSION_FROM   => 'EzPod.pm',
    NAME           => 'XML::Filter::EzPod',
    PREREQ_PM      => { 
                        'Test::More'        => 0,
                        'XML::SAX::Writer'  => 0,
                        'Pod::SAX'          => 0,
                        'XML::SAX::Base'    => 0.10,
                      },
    ABSTRACT_FROM  => 'EzPod.pm',
    AUTHOR         => 'Matt Sergeant <matt@sergeant.org>',
    clean          => {FILES => "tv.log"}
);
    
