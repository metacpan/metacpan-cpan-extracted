#!/usr/bin/env perl

###################################################################################################
# Author:        Olivier Delouya
# File:          t/14-look-around.t
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

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

plan tests => 2;

# -------------------------------------------------------------------------------------------------------
#           REGEX         INPUT      MATCH  LEN  FAIL_C  FAIL_TOKEN  LABEL                        OPT
# -------------------------------------------------------------------------------------------------------
check_tst( 'A(?=B)',     'AC',       0,     1,   'C',    '(?=B)',    "Lookahead failure",         [] );
check_tst( 'prix(?=\x{20ac})', 'prix$', 0,  4,   '$',    '(?=\x{20ac})', "Unicode lookahead",     [] );# Test suite definition (respecting your check_tst API)


done_testing();