###########################################################################
# $Id: Makefile.PL,v 1.3 2005/11/01 20:19:52 wendigo Exp $
###########################################################################
#
# Makefile.PM
#
# RCS Revision: $Revision: 1.3 $
# Date: $Date: 2005/11/01 20:19:52 $
#
# Copyright 2002 Mark Rogaski, mrogaski@cpan.org
#
# See the README file included with the
# distribution for license information.
#
###########################################################################
use 5.008;
use threads ();
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Thread::Barrier',
    'VERSION_FROM'	=> 'Barrier.pm',
    ($] >= 5.005 
        ?  (
            ABSTRACT_FROM => 'Barrier.pm', 
            AUTHOR        => 'Mark Rogaski <mrogaski@cpan.org>'
        ) 
        : ()),
    ($] < 5.008 
        ? () 
        : ( 
            NO_META => 1
        )),
);

