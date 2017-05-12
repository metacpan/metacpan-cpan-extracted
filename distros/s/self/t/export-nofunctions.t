#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use self ();

ok( !main->can('self') );
