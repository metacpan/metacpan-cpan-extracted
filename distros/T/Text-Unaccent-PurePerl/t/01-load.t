# -*- mode: perl; coding: us-ascii-unix -*-
#
# Author:      Peter John Acklam
# Time-stamp:  2013-03-02 12:40:43 +00:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

#########################

#use 5.008;              # for UTF-8 support
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
#use utf8;               # enable/disable UTF-8 (or UTF-EBCDIC) in source code

#########################

use Test::More tests => 1;

BEGIN { use_ok('Text::Unaccent::PurePerl'); }

diag("Testing Text::Unaccent::PurePerl $Text::Unaccent::PurePerl::VERSION, Perl $], $^X");
