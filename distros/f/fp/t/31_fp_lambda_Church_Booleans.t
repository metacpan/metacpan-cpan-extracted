#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use_ok('fp::lambda');
use_ok('fp::lambda::utils');

cmp_ok(AND(\&TRUE)->(\&FALSE), '==', \&FALSE, "AND TRUE FALSE is FALSE");
cmp_ok(OR(\&TRUE)->(\&FALSE), '==', \&TRUE, "OR TRUE FALSE is TRUE");

cmp_ok(cond(\&TRUE)->(\&five)->(\&four), '==', \&five, "IF TRUE THEN 5 ELSE 4 == 5");
cmp_ok(cond(\&TRUE)->(\&five)->(\&four), '!=', \&four, "IF TRUE THEN 5 ELSE 4 != 4");
cmp_ok(cond(\&FALSE)->(\&ten)->(\&four), '==', \&four, "IF FALSE THEN 10 ELSE 4 == 4");

cmp_ok(cond(OR(is_zero(\&zero))->(is_zero(\&one)))->(\&ten)->(\&three), '==', \&ten, "IF (OR (is_zero 0) (is_zero 1)) THEN 10 ELSE 3 == 10");
