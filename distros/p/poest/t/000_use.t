#!/usr/bin/perl
# $Id: 000_use.t,v 1.1 2003/03/12 20:42:39 cwest Exp $
use strict;
$^W = 1;

use Test::More qw[no_plan];

use lib qw[lib ../lib];

BEGIN {
	use_ok 'POEST::Server';

	use_ok 'POEST::Config';
	use_ok 'POEST::Config::General';

	use_ok 'POEST::Plugin';

	use_ok 'POEST::Plugin::General';
	use_ok 'POEST::Plugin::Check::Hostname';
}

1;
