#!/usr/bin/env perl -w
use strict;
use Test2::V0;
plan tests => 1;

use self ();

ok( !main->can('self') );
