#!/usr/env perl

# $Id: t0.t 39 2012-03-25 04:20:31Z stro $

use strict;
use warnings;

BEGIN {
    use Test;
    plan('tests' => 1);
}

use WWW::DreamHost::API;

ok(1); # sanity check and other modules skipping workaround
