#!/usr/bin/env perl

###################################################################################################
# Author:        Olivier Delouya
# File:          t/15-look-anchors.t
# Content:       bounds Quantifiers {n,m}
# Indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use Test::More;
use utf8;
use FindBin;
use lib $FindBin::Bin; 
use File::Spec;
use lib File::Spec->catdir('.', 't');

use Helper;



plan tests => 6;

# t/15-anchors.t
# -------------------------------------------------------------------------------------------------------
#           REGEX   INPUT   MATCH  LEN  FAIL_C  FAIL_TOKEN  LABEL                        OPT
# -------------------------------------------------------------------------------------------------------
check_tst(  '^A',   'A',    1,     1,   '',     '',         "Start anchor match",        [] );
check_tst(  '^A',   'BA',   0,     0,   'B',    'A',       "Start anchor failure",      [] );
check_tst(  'A$',   'A',    1,     1,   '',     '',         "End anchor match",          [] );
check_tst(  'A$',   'AB',   0,     1,   'B',    '$',        "End anchor failure",        [] );
check_tst(  '^AB$', 'AB',   1,     2,   '',     '',         "Full string anchor match",  [] );
check_tst(  '^AB$', 'ABC',  0,     2,   'C',    '$',        "Full string anchor fail",   [] );