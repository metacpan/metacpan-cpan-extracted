#!/usr/bin/perl -w
#############################################################################
## Name:        Makefile.PL
## Purpose:     Makefile.PL for wxPerl demo
## Author:      Mattia Barbon
## Modified by:
## Created:     14/08/2006
## RCS-ID:      $Id: Makefile.PL 2878 2010-04-04 05:21:30Z szabgab $
## Copyright:   (c) 2006-2007 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;

use ExtUtils::MakeMaker 6.46;

WriteMakefile
  ( NAME            => 'Wx::Demo',
    VERSION_FROM    => 'lib/Wx/Demo.pm',
    ABSTRACT_FROM   => 'lib/Wx/Demo.pm',
    PREREQ_PM       => { 'File::Spec'              => 0.8,
                         'Wx'                      => 0.64,
                         'Module::Pluggable'       => 3.1,
                         'UNIVERSAL::require'      => 0.10,
                         'Class::Accessor::Fast'   => 0.20,
                         'File::Slurp'             => 0.01,
                         'File::chdir'             => 0.06,
                         'IO::Scalar'              => 2.00,
                         },
    EXE_FILES       => [ qw(bin/wxperl_demo.pl) ],
    ( $] >= 5.005 ?
      ( AUTHOR          => 'Mattia Barbon <mbarbon@cpan.org>' ) :
      () ),

    # needs ExtUtils::MakeMaker 6.46
    META_MERGE => {
        no_index => {
            directory => ['lib/Wx/DemoModules/files/'],
        },
        resources => {
            license     => 'perl', # 'http://dev.perl.org/licenses/',
            homepage    => 'http://wxperl.sourceforge.net/',
            repository  => 'https://wxperl.svn.sourceforge.net/svnroot/wxperl/wxDemo/trunk',
            MailingList => 'wxperl-users@perl.org',
        },
    },
);

