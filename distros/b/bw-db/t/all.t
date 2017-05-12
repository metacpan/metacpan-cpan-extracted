#!/usr/bin/perl
# all.t by Bill Weinman <http://bw.org/contact/>
# test script for BW::DB
# Copyright (c) 2010 The BearHeart Group, LLC
# created 2010-02-17

use Test;
use strict;
use warnings;

BEGIN { plan tests => 6 }

eval { require BW::Base; return 1; };
ok( $@, '' );

eval { require BW::Constants; return 1; };
ok( $@, '' );

eval { use DBI; return 1; };
ok( $@, '' );

eval { use Digest::MD5; return 1; };
ok( $@, '' );

eval { use BW::DB; return 1; };
ok( $@, '' );

eval { use BW::DB::CRUD; return 1; };
ok( $@, '' );

exit 0;

