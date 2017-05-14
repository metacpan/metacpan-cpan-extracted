#!/home/jhildebr/bin/perl -w

use Devel::TraceFuncs qw(trace debug trace_file max_trace_depth);
use strict;

sub fq {
  trace(my $f);
  debug "que", "pee", "doll!";
}

sub fp {
  trace(my $f);
  fq();
  debug "cee", "dee";
}

sub fo {
  trace(my $f, "now", "then");
  &fp;
  debug "ha\nhs";
}

if (@ARGV) {
  max_trace_depth shift;
}

if (@ARGV) {
  trace_file shift;
}

trace(my $f, 0);
fo(4,5);

debug "done";
