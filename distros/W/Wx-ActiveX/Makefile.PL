#############################################################################
## Name:        Makefile.PL
## Purpose:     Makefile for Wx::ActiveX
## Author:      Graciliano M. P.
## SVN-ID:      $Id: Makefile.PL 3130 2011-11-22 01:34:58Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use strict;
use Wx::build::MakeMaker ;
use Config ;

my $libs = '' ;
my $ccflags = $Config{ccflags};
if( $Config{cc} =~ /^cl/i ) { 
    $libs = 'msvcprt.lib' ;
} else {
    $ccflags .= ' -Wno-multichar -Wno-write-strings';
}

wxWriteMakefile( NAME           => 'Wx::ActiveX',
                 ABSTRACT_FROM  => 'lib/Wx/ActiveX.pm',
                 VERSION_FROM   => 'lib/Wx/ActiveX.pm',
                 AUTHOR         => 'Graciliano M. P',
                 LIBS           => $libs ,
                 WX_CORE_LIB    => 'core base',
                 EXE_FILES      => [ qw(script/wxactivex_template.pl) ],
                 #NO_META        => 1,
                 WX_OVERLOAD    => {    header  => 'cpp/ovl_const.h',
                                        source  => 'cpp/ovl_const.cpp',
                                    },
                 PREREQ_PM  => { Wx   => '0.57' },
                 CCFLAGS    => $ccflags,
               );

# 

# local variables:
# mode: cperl
# end:
