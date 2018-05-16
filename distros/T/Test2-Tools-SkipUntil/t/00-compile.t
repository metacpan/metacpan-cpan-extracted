#!/usr/bin/perl
use Test2::Tools::Basic;
plan 1;

eval 'require Test2::Tools::SkipUntil';
if (my $err = $@) {
  fail "Failed to import Test2::Tools::SkipUntil: $err";
}
else {
  pass 'Imported Test2::Tools::SkipUntil';
}
