#!/usr/local/bin/perl
###########################################################################
# $Id: 00_load.t,v 1.2 1999/09/21 05:42:19 wendigo Exp $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 1999/09/21 05:42:19 $
#
###########################################################################
#
# See README for license information.
# 
###########################################################################

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tree::Ternary_XS;
$loaded = 1;
print "ok 1\n";
