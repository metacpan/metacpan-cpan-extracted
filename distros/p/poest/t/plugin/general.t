#!/usr/bin/perl
# $Id: general.t,v 1.2 2003/03/22 17:06:17 cwest Exp $
use strict;
$^W = 1;

use Test::More qw[no_plan];
use lib qw[lib ../lib];

BEGIN {
	use_ok 'POEST::Config::General';
}
