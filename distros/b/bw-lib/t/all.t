#!/usr/bin/perl
# base.t by Bill Weinman <http://bw.org/contact/>
# test script for BW-Lib
# Copyright (c) 2010 The BearHeart Group, LLC
# created 2010-02-15
#
use Test;
use strict;
use warnings;

BEGIN { plan tests => 11 }

eval { require BW::Base; return 1; };
ok( $@, '' );

eval { require BW::AddressCodes; return 1; };
ok( $@, '' );

eval { require BW::CGI; return 1; };
ok( $@, '' );

eval { require BW::Common; return 1; };
ok( $@, '' );

eval { require BW::Config; return 1; };
ok( $@, '' );

eval { require BW::Constants; return 1; };
ok( $@, '' );

eval { require BW::Email; return 1; };
ok( $@, '' );

eval { require BW::Include; return 1; };
ok( $@, '' );

eval { require BW::Jumptable; return 1; };
ok( $@, '' );

eval { require BW::XML::Out; return 1; };
ok( $@, '' );

eval { require BW::XML::HTML; return 1; };
ok( $@, '' );

exit 0;

