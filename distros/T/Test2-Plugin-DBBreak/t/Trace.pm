package Trace;

sub DB::DB {
  my ($p, $f, $l) = caller;
  my $code = \@{"::_<$f"};
  print "($DB::single) >> $f:$l: $code->[$l]";
  $DB::single = 0;
}

1;
