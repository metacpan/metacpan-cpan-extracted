#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

{
  my $script = <<'END';
package 
  t1;
use YATT::Lite::Partial::ErrorReporter;
END

  eval $script;
  is $@, '', "t1 is compiled correctly";

  my $t1 = bless({}, 't1');

  like my $e1 = $t1->error({tmpl_file => __FILE__, tmpl_line => __LINE__}, "foobar"), qr!^foobar at file @{[__FILE__]} line @{[__LINE__]}!
    , "error string";
  is $e1->reason, "foobar", "->reason";

  is my $e2 = $t1->error("foobar %d", 3), "foobar 3"
    , "error string, with arguments";

  is_deeply $e2->cget('args'), [3], "->cget(args)";
}

done_testing();
