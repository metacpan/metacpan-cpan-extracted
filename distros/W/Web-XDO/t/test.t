#!/usr/bin/perl -w
use strict;
# use lib '../../';
use Web::XDO;
use Test;

# NOTE: I'm not sure what to test.  Everything in this module is for use in a
# web environment, so for now just testing that the script can load Web::XDO.

BEGIN { plan tests => 1 };

ok(1);
