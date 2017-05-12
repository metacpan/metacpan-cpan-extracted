#############################################################################
## Name:        Makefile.PL
## Purpose:     Makefile
## Author:      Mattia Barbon
## Modified by:
## Created:     26/07/2003
## RCS-ID:      $Id: Makefile.PL 2410 2008-06-29 19:32:37Z mbarbon $
## Copyright:   (c) 2003, 2005, 2007-2008 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;
use lib 'inc';
use MyMakeMaker;

my %requires =
  ( 'Wx'                   => '0.57',
    'Wx::build::MakeMaker' => '0.16',
    );

eval {
    require ExtUtils::MY_Metafile;
    ExtUtils::MY_Metafile->import;

    my_metafile
      ( { license            => 'perl',
          dynamic_config     => 1,
          requires           => \%requires,
          build_requires     => {},
          configure_requires => { 'Wx::build::MakeMaker' => '0.16',
                                  },
          } );
};

wxWriteMakefile( NAME          => 'Wx::GLCanvas',
                 ABSTRACT_FROM => 'lib/Wx/GLCanvas.pm',
                 AUTHOR        => 'Mattia Barbon <mbarbon@cpan.org>',
                 VERSION_FROM  => 'lib/Wx/GLCanvas.pm',
                 LIBS          => ( $^O eq 'MSWin32' ? '-lopengl32' : '' ),
                 WX_CORE_LIB   => 'gl core base',
                 WX_OVERLOAD   => { header  => 'cpp/ovl_const.h',
                                    source  => 'cpp/ovl_const.cpp',
                                    },
                 PREREQ_PM     => \%requires,
                 LICENSE       => 'perl',
                 );
