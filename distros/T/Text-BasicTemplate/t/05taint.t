#!/usr/bin/perl -w
# $Id: 05taint.t,v 1.1 1999/11/13 10:34:59 aqua Exp $

# There has _got_ to be a better way.  At the moment it's pitiful
# that what MakeMaker thinks of as the test code for the taint
# check checks is the most obviously tainted.

system($^X,'-Tw','-Iblib/arch','-Iblib/lib','t/05-real.pl');
