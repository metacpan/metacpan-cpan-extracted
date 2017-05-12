#!/usr/bin/perl -w

# An error in base.pm in 5.005_03 causes it not to load URI::Find when
# invoked from URI::Find::Schemeless.  Prevent regression.

use strict;

use Test::More tests => 2;

require_ok 'URI::Find::Schemeless';
new_ok 'URI::Find::Schemeless' => [sub {}];
