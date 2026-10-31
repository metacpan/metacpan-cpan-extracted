#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl" }
#----------------------------------------

use base qw/YATT::Lite::Object
	    YATT::Lite::Util::CmdLine/;
use fields qw/file debug/;

MY->run(\@ARGV);

sub cmd_test {
  (my MY $self, my @args) = @_;
  print "TEST(@args)\n";
}
