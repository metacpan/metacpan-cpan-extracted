#!/usr/local/bin/perl
###########################################################################
# $Id: 04_attrib.t,v 1.2 1999/09/21 05:42:22 wendigo Exp $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 1999/09/21 05:42:22 $
#
###########################################################################
#
# See README for license information.
#
###########################################################################

use Test;
use Tree::Ternary_XS;

BEGIN { plan tests => 4 }

ok($ref = new Tree::Ternary_XS);
ok(ref($ref), 'Tree::Ternary_XS');

ok($ref->nodes(), 0);
ok($ref->terminals(), 0);

