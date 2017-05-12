package ok;
sub import {
  my $package = shift;
  if ($package eq "ok") {
    print "ok @_\n";
  } else {
    print "not ok @_\n";
  }
}
1;
