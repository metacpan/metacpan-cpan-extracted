#!/usr/local/bin/perl
###########################################################################
# $Id: 15_search.t,v 1.2 1999/09/21 05:42:23 wendigo Exp wendigo $
###########################################################################
#
# Author: Mark Rogaski <wendigo@pobox.com>
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 1999/09/21 05:42:23 $
#
###########################################################################
#
# See README for license information.
#
###########################################################################

use Test;
use Tree::Ternary_XS;

BEGIN { plan tests => 8 }

$ref = new Tree::Ternary_XS;

ok($ref->insert("foobar"));

ok($ref->insert("bloodhound"));

ok($ref->search("foobar"), 1);

ok($ref->search("foo"), 0);

ok($ref->search("foobaz"), 0);

ok($ref->search("pianosaurus"), 0);

ok($ref->search("blood"), 0);

ok($ref->search("bloodhound"), 1);



