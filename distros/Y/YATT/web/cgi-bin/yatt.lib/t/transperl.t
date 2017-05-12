#!/usr/bin/perl -w
# -*- mode: perl; coding: utf-8 -*-
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
use lib "$FindBin::Bin/..";

#========================================
use YATT::Test;
use base qw(YATT::Test);

my $ROOTNAME = rootname($0);

__PACKAGE__->xhf_test("$ROOTNAME.tmp"
		      , @ARGV ? @ARGV : $ROOTNAME)

# To see generated code, set $ENV{DEBUG}
