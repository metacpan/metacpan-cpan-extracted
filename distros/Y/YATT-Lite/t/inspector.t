#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;

require_ok('YATT::Lite::Inspector');

{
  my $test = sub {
    my ($before, $changeList, $expect, $title) = @_;
    my $got = YATT::Lite::Inspector->apply_all_change_to_lines($before, $changeList);
    is_deeply($got, $expect, $title);
  };

  $test->(
    ["foo", "bar"],
    [{"range" =>
      {"end" => {"character" => 0,"line" => 0}
       ,"start" => {"character" => 0,"line" => 0}}
      ,"rangeLength" => 0,"text" => "\n"}],
    ["", "foo", "bar"],
    "insert first newline"
  );

  $test->(
    ["foo", "bar"],
    [{"range" =>
      {"end" => {"character" => 0,"line" => 1}
       ,"start" => {"character" => 3,"line" => 0}}
      ,"rangeLength" => 0,"text" => "\nqux\nquuux"}],
    ["foo", "qux", "quuuxbar"],
    "insert multiline changes with newlines"
  );

}

done_testing();

